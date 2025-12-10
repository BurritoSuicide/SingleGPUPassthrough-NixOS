{ pkgs, ... }:

with pkgs; [
  # Image processing libraries
  imagemagick  # Image manipulation library
  libjpeg      # JPEG library
  libpng       # PNG library
]

