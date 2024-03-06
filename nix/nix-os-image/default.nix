{
  pkgs,
  outputs,
  inputs,
  nixpkgs,
  ...
}: let
  image = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = inputs;
    modules = [
      ./configuration.nix
      "${inputs.nixpkgs}/nixos/modules/installer/sd-card/sd-image-armv7l-multiplatform.nix"
      {
        nixpkgs.hostPlatform.system = "armv7l-linux";
        nixpkgs.buildPlatform.system = "x86_64-linux";
      }
    ];
  };
in {
  outputs.image = image.config.system.build.sdImage;
}
