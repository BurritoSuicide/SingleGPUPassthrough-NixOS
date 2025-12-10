{ pkgs, unstablePkgs, ... }:

with pkgs; [
  # Image editing
  gimp     # GNU Image Manipulation Program
  krita    # Digital painting and image editing
  hyprshot # Screenshot tool for Hyprland
  unstablePkgs.upscayl  # AI image upscaling tool
]

