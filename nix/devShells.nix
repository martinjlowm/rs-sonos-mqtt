{inputs, ...}: {
  default = {
    pkgs,
    rustToolchain,
  }:
    inputs.devenv.lib.mkShell
    {
      inherit inputs pkgs;

      modules = [
        {
          packages = with pkgs; [
            cargo-nextest

            # Nix
            nil
            alejandra
          ];

          difftastic.enable = true;

          languages.rust = {
            enable = true;
            toolchain.rustc = rustToolchain;
          };

          pre-commit.hooks = {
            clippy.enable = true;
            rustfmt.enable = true;
            alejandra.enable = true;
            statix.enable = true;
          };
        }
      ];
    };
}
