{ pkgs, ... }:

with pkgs; [
  # Music streaming services
  tidal-dl   # Tidal downloader
  tidal-hifi # Tidal HiFi client
  spotify    # Spotify client
]

