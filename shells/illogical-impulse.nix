{ config, pkgs, lib, illogicalImpulse ? null, gitPkgs ? {}, unstablePkgs, ... }:

lib.mkIf (illogicalImpulse != null) {
  # Configure illogical-impulse
  # Note: The module is imported in home.nix to make options available
  # The module will set up quickshell config and packages
  # We disable hyprland config from the module since we manage it separately
  illogical-impulse = {
    enable = true;
    hyprland = {
      # Use our existing Hyprland package (don't override)
      package = pkgs.hyprland;
      xdgPortalPackage = pkgs.xdg-desktop-portal-hyprland;
      ozoneWayland.enable = true;
      # Use default monitor configuration
      monitor = [ ",preferred,auto,1" ];
    };
    # Enable dotfiles components (optional - adjust as needed)
    dotfiles = {
      kitty.enable = false;  # We may already have kitty configured
      fish.enable = false;   # We may already have fish configured
      starship.enable = false;  # We may already have starship configured
    };
  };

  # Disable the hyprland module part since we manage Hyprland separately
  # The module's hyprland.nix would try to enable wayland.windowManager.hyprland
  # which conflicts with our system-level Hyprland configuration
  wayland.windowManager.hyprland.enable = lib.mkForce false;

  # Illogical Impulse shell user service is defined in home.nix
  # to avoid conflicts and ensure proper Qt environment setup
}

