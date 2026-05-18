{
  pkgs ? import <nixpkgs> { }
}:
let
  overrides = (builtins.fromTOML (builtins.readFile ./rust-toolchain.toml));
in
pkgs.callPackage (
  {
    stdenv
  , lib
  , pkgs
  , mkShell
  , rustup
  , clang
  , lld
  , pkg-config
  , libGL
  , libX11
  , libxcb
  , libxcb-wm
  , libxcursor
  , alsa-lib
  , libjack2
  , rustPlatform
  , egl-wayland
  , wayland
  , fontconfig
  , freetype
  }:
  mkShell rec {
    strictDeps = true;
    nativeBuildInputs = [
      (pkgs.pkgsCross.mingwW64.buildPackages.gcc.override { 
        extraBuildCommands = ''
          printf '%s' '-L${libjack2}/lib' >> $out/nix-support/cc-ldflags
          printf '%s' '-I${libjack2.dev}/include' >> $out/nix-support/cc-cflags
          printf '%s' '-L${pkgs.pkgsCross.mingw32.windows.mcfgthreads}/lib' >> $out/nix-support/cc-ldflags
          printf '%s' '-I${pkgs.pkgsCross.mingw32.windows.mcfgthreads.dev}/include' >> $out/nix-support/cc-cflags
        '';
      })
      libjack2
      rustup
      rustPlatform.bindgenHook
      egl-wayland
      wayland
      pkg-config
      lld
    ];

    buildInputs = [
      (pkgs.pkgsCross.mingwW64.windows.mcfgthreads.overrideAttrs {
        dontDisableStatic = true;
      })
      pkgs.pkgsCross.mingwW64.windows.pthreads
      libGL
      libjack2
      libX11
      libxcb
      libxcb-wm
      libxcursor
      alsa-lib
      fontconfig
      freetype
    ];
    RUSTC_VERSION = overrides.toolchain.channel;
    # https://github.com/rust-lang/rust-bindgen#environment-variables
    shellHook = ''
      export LD_LIBRARY_PATH=${lib.makeLibraryPath nativeBuildInputs}:$LD_LIBRARY_PATH
      export LIBRARY_PATH=${lib.makeLibraryPath nativeBuildInputs}/lib:$LIBRARY_PATH
      export PATH=''${CARGO_HOME:-~/.cargo}/bin:$PATH
      export PATH=''${RUSTUP_HOME:-~/.rustup}/toolchains/$RUSTC_VERSION-${stdenv.hostPlatform.rust.rustcTarget}/bin:"$PATH
    '';
  }
) { }
