{
  description = "NixOS with Sonos service listening for commands through AWS IoT";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    home-manager = {
      url = "github:nix-community/home-manager/release-23.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
    ...
  } @ inputs:
    flakelight ./. (_: rec {
      inherit inputs;
      systems = ["x86_64-darwin" "x86_64-linux"];
      withOverlays = [
        (_: _: {inherit crane;})
        (final: _: let
          loadPkgs = import nixpkgs;
        in
          with final; {
            armv7l-linux = loadPkgs {
              localSystem = system;
              crossSystem = "armv7l-linux";
              overlays = [(import rust-overlay)];
            };
            x86_64-linux = loadPkgs {
              localSystem = system;
              crossSystem = "x86_64-linux";
              overlays = [(import rust-overlay)];
            };
            aarch64-linux = loadPkgs {
              localSystem = system;
              crossSystem = "aarch64-linux";
              overlays = [(import rust-overlay)];
            };
            x86_64-darwin = loadPkgs {
              localSystem = system;
              crossSystem = "x86_64-linux";
              overlays = [(import rust-overlay)];
            };
            aarch64-darwin = loadPkgs {
              localSystem = system;
              crossSystem = "aarch64-darwin";
              overlays = [(import rust-overlay)];
            };
          })
        (import rust-overlay)
      ];
      imports = [
        ./nix
      ];
    });
}
