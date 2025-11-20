{ pkgs, ... }:

with pkgs; [
  # Image processing libraries (for caelestia wallpaper support)
  imagemagick  # Image manipulation library
  libjpeg      # JPEG library
  libpng       # PNG library
]

