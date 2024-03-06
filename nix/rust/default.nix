{src, ...}: {
  withOverlays = [
    (final: _:
      with final; {
        rustToolchain = pkgs.pkgsBuildHost.rust-bin.fromRustupToolchainFile (src + /rust-toolchain.toml);
        craneLib = (crane.mkLib pkgs).overrideToolchain rustToolchain;
        rustSrcWithRequiredFiles = pkgs.lib.cleanSourceWith {
          inherit src;
        };
        rustDeps = craneLib.buildDepsOnly {
          cargoBuildCommand = "true";
        };
      })
  ];
}
