{ pkgs, ... }:

with pkgs; [
  # Wayland compositor and window management
  hyprlock  # Hyprland lock screen
  
  # Application launchers
  wofi      # Wayland launcher
  bemenu    # Wayland menu
  
  # Terminal emulators
  kitty     # GPU-accelerated terminal
  foot      # Fast, lightweight terminal
  
  # Wayland utilities
  brightnessctl  # Brightness control
  playerctl      # Media player control
  pamixer        # PulseAudio mixer
  libnotify      # Desktop notifications
  
  # Wallpaper and theming
  swww      # Animated wallpaper daemon
  hyprpaper # Hyprland wallpaper daemon
  nwg-look  # GTK theme switcher
  
  # XDG utilities
  xdg-utils        # XDG desktop integration
  xdgmenumaker     # Generate XDG menus
  shared-mime-info # MIME type database
  desktop-file-utils  # Desktop file utilities
  
  # GTK utilities (needed for gtk-launch to launch applications from dock)
  gtk3             # GTK3 library (provides gtk-launch for desktop entry execution)
  
  # Shell prompt
  starship  # Cross-shell prompt
]