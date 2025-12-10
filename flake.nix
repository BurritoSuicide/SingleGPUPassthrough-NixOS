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

    # DankMaterialShell dependencies
    dgop = {
      url = "github:AvengeMedia/dgop";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # DankMaterialShell
    dankMaterialShell = {
      url = "github:AvengeMedia/DankMaterialShell";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.dgop.follows = "dgop";
    };

    # SilentSDDM theme
    silentSDDM = {
      url = "github:uiriansan/SilentSDDM";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, unstable, home-manager, dgop, dankMaterialShell, silentSDDM }:
    let
      system = "x86_64-linux";
      unstablePkgs = import unstable {
        inherit system;
        config.allowUnfree = true;
      };
    in {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix

        # Nixpkgs configuration (flake-based)
        {
          nixpkgs.config.allowUnfree = true;
          nixpkgs.config.permittedInsecurePackages = [
            "ventoy-qt5-1.1.05"
            "electron-36.9.5"
          ];
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
                inherit unstablePkgs;
                inherit dankMaterialShell;
              };
        }

        # Pass additional package sets and inputs as arguments
        {
          _module.args = {
            inherit unstablePkgs;
            inherit silentSDDM;
          };
        }
      ];
    };
  };
}
