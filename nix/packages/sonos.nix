{
  src,
  pkgsBuildHost,
  crane,
  stdenv,
  pkgs,
}: let
  rustToolchain = pkgsBuildHost.rust-bin.fromRustupToolchainFile (src + /rust-toolchain.toml);
  craneLib = (crane.mkLib pkgs).overrideToolchain rustToolchain;
in
  craneLib.buildPackage {
    src = craneLib.cleanCargoSource (craneLib.path src);
  }
