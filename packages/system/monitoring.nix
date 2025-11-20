{ pkgs, ... }:

with pkgs; [
  # GPU monitoring
  radeontop   # AMD GPU monitoring
  amdgpu_top  # AMD GPU monitoring tool
  
  # Calendar and scheduling
  gcalcli     # Google Calendar CLI
  
  # Calculator
  libqalculate  # Advanced calculator library
]

