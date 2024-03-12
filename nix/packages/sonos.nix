{
  src,
  pkgsBuildHost,
  crane,
  stdenv,
  pkgs,
}: {craneExtraArgs ? {}}: let
  rustToolchain = builtins.trace pkgs.pkgsBuildHost.system (pkgs.pkgsBuildHost.rust-bin.fromRustupToolchainFile (src + /rust-toolchain.toml));
  craneLib = (crane.mkLib pkgs.pkgsBuildHost).overrideToolchain rustToolchain;
in
  craneLib.buildPackage (builtins.trace ({
        src = craneLib.cleanCargoSource (craneLib.path src);
      }
      // craneExtraArgs) {
      src = craneLib.cleanCargoSource (craneLib.path src);
    }
    // craneExtraArgs)
