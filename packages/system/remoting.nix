{ pkgs, ... }:

with pkgs; [
  # Remote access and display
  xorg.xrandr  # X11 RandR extension (display configuration)
  openssl      # SSL/TLS toolkit
]

