{
  src,
  pkgsBuildHost,
  crane,
  stdenv,
  pkgs,
}: {craneExtraArgs ? {}}: let
  rustToolchain = pkgs.pkgsBuildHost.rust-bin.fromRustupToolchainFile (src + /rust-toolchain.toml);
  craneLib = (crane.mkLib pkgs.pkgsBuildHost).overrideToolchain rustToolchain;
in
  craneLib.buildPackage {
    src = craneLib.cleanCargoSource (craneLib.path src);
  }
  // craneExtraArgs
