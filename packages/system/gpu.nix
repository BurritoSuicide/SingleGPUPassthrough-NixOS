{ pkgs, ... }:

with pkgs; [
  # GPU tuning and management
  lact  # Linux AMD GPU Controller (GPU tuning tool)
  # Note: e2fsprogs moved to disk.nix as it's a filesystem utility, not GPU-related
]

