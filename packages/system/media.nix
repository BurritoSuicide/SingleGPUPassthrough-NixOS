{ pkgs, ... }:

with pkgs; [
  # Media players
  mpv       # Video player
  mpvpaper  # Video wallpaper for mpv
  vlc       # Media player
  
  # Media processing
  ffmpeg    # Multimedia framework
  
  # Audio
  wireplumber  # Audio session manager
  pavucontrol  # PulseAudio volume control
  
  # Build tools (CSS preprocessing)
  sassc        # Sass/SCSS compiler (used for styling themes)
  
  # Network utilities for media
  socat     # Multipurpose relay
]

