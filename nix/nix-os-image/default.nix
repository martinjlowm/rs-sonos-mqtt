{
  inputs,
  pkgsFor,
  ...
}: let
  image = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = inputs;
    modules = [
      {
        nixpkgs = {
          hostPlatform.system = "armv7l-linux";
          buildPlatform.system = "x86_64-linux";
          overlays = [(final: _: {inherit (pkgsFor.x86_64-linux) sonos;})];
        };
      }
      inputs.home-manager.nixosModules.home-manager
      ./configuration.nix
      "${inputs.nixpkgs}/nixos/modules/installer/sd-card/sd-image-armv7l-multiplatform.nix"
    ];
  };
in {
  outputs.image = image.config.system.build.sdImage;
}
