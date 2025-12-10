{ config, pkgs, lib, unstablePkgs, dankMaterialShell, ... }:

{
  # ============================================================================
  # Imports
  # ============================================================================
  # Import quickshell module to provide options (needed by DankMaterialShell)
  # Note: We don't enable it, but make the options available
  imports = [
    ./modules/quickshell.nix
    dankMaterialShell.homeModules.dankMaterialShell.default
  ];

  # ============================================================================
  # Home Manager Basic Configuration
  # ============================================================================
  home.username = "scryv";
  home.homeDirectory = "/home/scryv";
  home.stateVersion = "25.05";
  programs.home-manager.enable = true;

  # ============================================================================
  # User Packages
  # ============================================================================
  # User packages (organized in packages/user/)
  home.packages = let
    userPackagesDir = builtins.path {
      path = ./packages/user;
      name = "user-packages";
      filter = path: type: true;
    };
    userPkgs = import (toString userPackagesDir + "/default.nix") {
      inherit pkgs unstablePkgs;
    };
  in userPkgs;

  # ============================================================================
  # Program Configuration
  # ============================================================================
  programs.git = {
    enable = true;
  };

  # ============================================================================
  # Hyprland Configuration
  # ============================================================================
  # Link Hyprland config and scripts to ~/.config/hypr/
  xdg.configFile."hypr/hyprland.conf".source = ./hypr/hyprland.conf;
  xdg.configFile."hypr/scripts" = {
    source = ./hypr/scripts;
    recursive = true;
    executable = true;  # Make scripts executable
  };
  xdg.configFile."hypr/scheme" = {
    source = ./hypr/scheme;
    recursive = true;
  };

  # ============================================================================
  # DankMaterialShell Configuration
  # ============================================================================
  programs.dankMaterialShell = {
    enable = true;
    
    systemd = {
      enable = true;
      restartIfChanged = true;
    };
    
    # Core features
    enableSystemMonitoring = true;
    enableClipboard = true;
    enableVPN = true;
    # enableBrightnessControl and enableColorPicker are now built-in, no longer needed
    enableDynamicTheming = true;
    enableAudioWavelength = true;
    enableCalendarEvents = true;
    enableSystemSound = true;
  };

  # Override the dms.service to ensure PATH includes quickshell
  # DankMaterialShell needs quickshell (qs) in PATH
  # Get quickshell from DankMaterialShell's inputs
  systemd.user.services.dms = let
    system = "x86_64-linux";
    quickshellPkg = dankMaterialShell.inputs.quickshell.packages.${system}.default;
  in {
    Service = {
      # Add quickshell from DankMaterialShell's inputs to PATH
      Environment = [
        "PATH=${quickshellPkg}/bin:/home/scryv/.nix-profile/bin:/nix/profile/bin:/home/scryv/.local/state/nix/profile/bin:/etc/profiles/per-user/scryv/bin:/nix/var/nix/profiles/default/bin:/run/current-system/sw/bin:/run/wrappers/bin"
      ];
    };
  };
}
