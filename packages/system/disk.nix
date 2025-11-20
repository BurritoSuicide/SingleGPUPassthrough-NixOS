{ pkgs, ... }:

with pkgs; [
  # Disk and filesystem utilities
  e2fsprogs  # Ext2/3/4 filesystem utilities
  ncdu       # Disk usage analyzer
]

