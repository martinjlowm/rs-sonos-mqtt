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
          # aws-lc fails to compile because of header include conflict which is
          # resolved in a later SDK version, however, Nix is stuck on an old
          # version https://github.com/NixOS/nixpkgs/pull/229210
          env = {
            C_INCLUDE_PATH = "/Library/Developer/CommandLineTools/SDKs/MacOSX14.4.sdk/usr/include";
            ROOT_CERTIFICATE_PATH = "${builtins.getEnv "PWD"}/AmazonRootCA1.pem";
            PRIVATE_KEY_PATH = "${builtins.getEnv "PWD"}/d8cfa7474fa13770a7cf862563be03425957469e96ce221b42af933018b126d5-private.pem.key";
            CERTIFICATE_PATH = "${builtins.getEnv "PWD"}/d8cfa7474fa13770a7cf862563be03425957469e96ce221b42af933018b126d5-certificate.pem.crt";
            AWS_ENDPOINT = "aoe86ov002i0d-ats.iot.eu-west-1.amazonaws.com";
            CLIENT_ID = "sonos";
          };

          packages = with pkgs;
            [
              cargo-nextest

              # Nix
              nil
              alejandra
              libcxxabi
            ]
            ++ lib.optionals stdenv.isDarwin (with darwin; [
              apple_sdk.frameworks.Security
              apple_sdk.frameworks.SystemConfiguration
              apple_sdk.frameworks.CoreFoundation
            ]);

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

          scripts.flash.exec = ''
            sudo ${pkgs.zstd}/bin/zstd -vdcfT6 result/sd-image/nixos-sd-image*.img.zst | sudo dd status=progress bs=4M of="$1"
          '';
        }
      ];
    };
}
