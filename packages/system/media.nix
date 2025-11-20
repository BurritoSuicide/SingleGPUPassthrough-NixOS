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
  sassc        # Sass compiler (for styling)
  
  # Network utilities for media
  socat     # Multipurpose relay
]

