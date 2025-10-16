{
  description = "Your NixOS configuration";

  inputs = {
    # Stable channel (25.05)
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";

    # Unstable channel
    unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Home Manager (following stable)
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Git-based packages
    quickshell = {
      url = "git+https://git.outfoxxed.me/outfoxxed/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    caelestia-shell = {
      url = "github:caelestia-dots/shell";
      inputs.nixpkgs.follows = "unstable";
    };
  };

  outputs = { self, nixpkgs, unstable, home-manager, quickshell, caelestia-shell }:
    let
      system = "x86_64-linux";
      unstablePkgs = import unstable {
        inherit system;
        config.allowUnfree = true;
      };
      gitPkgs = {
        quickshell = quickshell.packages.${system}.default;
        caelestia-shell = caelestia-shell.packages.${system}.default;
      };
    in {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix

        # Home Manager module
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.scryv = import ./home.nix;
          home-manager.extraSpecialArgs = {
            inherit unstablePkgs;
            caelestia = caelestia-shell;
          };
        }

        # Pass additional package sets as arguments
        {
          _module.args = {
            inherit unstablePkgs gitPkgs;
          };
        }
      ];
    };
  };
}
