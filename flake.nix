{
  description = "NixOS with Sonos service listening for commands through AWS IoT";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flakelight = {
      url = "github:accelbread/flakelight";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    devenv = {
      url = "github:cachix/devenv";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };
    crane = {
      url = "github:ipetkov/crane";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        rust-overlay.follows = "rust-overlay";
        flake-compat.follows = "devenv";
      };
    };
  };

  outputs = {
    self,
    nixpkgs,
    flakelight,
    crane,
    devenv,
    rust-overlay,
  } @ inputs:
    flakelight ./. (_: rec {
      inherit inputs;
      systems = ["x86_64-darwin"];
      withOverlays = [
        (_: _: {inherit crane;})
        (import rust-overlay)
      ];
      imports = [
        ./nix
      ];
    });
}
