{
  description = "macOS Ventura VM with NixThePlanet";

  inputs = {
    nixtheplanet.url = "github:matthewcroughan/nixtheplanet";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.05";
  };

  outputs = { self, nixpkgs, nixtheplanet }: {

    # Build a Darwin disk image of 60 GB
    darwinImage = nixtheplanet.legacyPackages.x86_64-linux.makeDarwinImage {
      diskSizeBytes = 100_000_000_000; # 60 GB
    };

    # NixOS VM configuration for running the macOS VM
    nixosConfigurations.my-machine = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        nixtheplanet.nixosModules.macos-ventura
        {
          services.macos-ventura = {
            enable = true;
            openFirewall = true;          # Allow incoming connections
            vncListenAddr = "0.0.0.0";    # Listen on all interfaces
            enableSSH = true;             # Enable SSH in macOS guest
            sshPort = 2222;               # Forwarded port
          };
        }
      ];
    };
  };
}
