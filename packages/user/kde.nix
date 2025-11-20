{ pkgs, ... }:

with pkgs; [
  # KDE applications
  kdePackages.kate                    # Advanced text editor
  kdePackages.dolphin                 # File manager
  kdePackages.qt6ct                   # Qt6 configuration tool
  kdePackages.kdegraphics-thumbnailers # Graphics thumbnailers
  kdePackages.ffmpegthumbs            # Video thumbnails
]

