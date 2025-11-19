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
      inputs.nixpkgs.follows = "unstable";  # Use unstable for Qt 6.10+ support
    };

    caelestia-shell = {
      url = "github:caelestia-dots/shell";
      inputs.nixpkgs.follows = "unstable";
    };

    dankMaterialShell = {
      url = "github:AvengeMedia/DankMaterialShell";
      inputs.nixpkgs.follows = "unstable";
    };
    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "unstable";
      inputs.quickshell.follows = "quickshell";
    };
  };

  outputs = { self, nixpkgs, unstable, home-manager, quickshell, caelestia-shell, dankMaterialShell, noctalia }:
    let
      system = "x86_64-linux";
      unstablePkgs = import unstable {
        inherit system;
        config.allowUnfree = true;
      };
      gitPkgs = {
        quickshell = quickshell.packages.${system}.default;  # Now built against unstable Qt
        caelestia-shell = caelestia-shell.packages.${system}.default;
      };
    in {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix

        # Nixpkgs configuration (flake-based)
        {
          nixpkgs.config.allowUnfree = true;
          nixpkgs.config.permittedInsecurePackages = [ "ventoy-qt5-1.1.05" ];
          nixpkgs.config.allow32bit = true;
        }

        # Home Manager module
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.backupFileExtension = "backup";
          home-manager.users.scryv = import ./home.nix;
          home-manager.extraSpecialArgs = {
            inherit unstablePkgs gitPkgs;
            caelestia = caelestia-shell;
            dms = dankMaterialShell;
            noctaliaInput = noctalia;
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
