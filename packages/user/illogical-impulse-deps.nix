{ pkgs, unstablePkgs, ... }:

# Illogical Impulse shell dependencies
# Based on: https://github.com/end-4/dots-hyprland/blob/main/sdata/deps-info.md
# This file contains all the dependencies needed for the Illogical Impulse shell to work properly

with pkgs; [
  # ============================================================================
  # Audio (illogical-impulse-audio)
  # ============================================================================
  cava                    # Audio visualizer (used in Quickshell config)
  pavucontrol             # PulseAudio volume control (Qt version preferred but standard works)
  # wireplumber - already in system packages
  # pipewire-pulse - already enabled in configuration.nix
  libdbusmenu-gtk3        # D-Bus menu for GTK3 applications

  # ============================================================================
  # Backlight (illogical-impulse-backlight)
  # ============================================================================
  # geoclue - already enabled as service in configuration.nix
  # brightnessctl - already in wayland.nix
  # ddcutil - already in wayland-unstable.nix

  # ============================================================================
  # Basic (illogical-impulse-basic)
  # ============================================================================
  # bc - already in sysutil.nix
  # coreutils - already in system
  cliphist                # Clipboard history manager (used in Hyprland and Quickshell)
  # cmake - build dependency, usually available
  # curl - already in sysutil.nix
  # wget - already in sysutil.nix
  # ripgrep - might be in system
  # jq - already in sysutil.nix
  xdg-user-dirs           # XDG user directories (used in Hyprland and Quickshell)
  # rsync - usually in system
  yq-go                   # YAML processor (go-yq equivalent)

  # ============================================================================
  # Fonts and Themes (illogical-impulse-fonts-themes)
  # ============================================================================
  adw-gtk3                # GTK theme (used in Quickshell config)
  # breeze - already available via KDE
  # breeze-plus - might need to be built from source or use breeze-icons
  # darkly-bin - Qt theme, might need custom package
  # eza - already in sysutil.nix
  # fish - already enabled in configuration.nix
  # fontconfig - basic component
  # kitty - already in wayland.nix
  # matugen - already in theming.nix
  # starship - already in wayland.nix
  
  # Fonts
  # otf-space-grotesk - might need custom package or use similar font
  # ttf-jetbrains-mono-nerd - already in fonts (nerd-fonts.jetbrains-mono)
  # ttf-material-symbols-variable - might need custom package
  # ttf-readex-pro - might need custom package
  # ttf-rubik-vf - might need custom package
  # ttf-twemoji - might need custom package or use noto-fonts-emoji

  # ============================================================================
  # Hyprland (illogical-impulse-hyprland)
  # ============================================================================
  # hyprland - already enabled in configuration.nix
  hyprsunset              # Hyprland night light (used in Quickshell config)
  wl-clipboard            # Wayland clipboard utilities (surely needed)

  # ============================================================================
  # KDE (illogical-impulse-kde)
  # ============================================================================
  kdePackages.bluedevil   # Bluetooth manager
  gnome-keyring           # Keyring daemon (provides gnome-keyring-daemon)
  # networkmanager - already enabled in configuration.nix
  # plasma-nm - part of KDE Plasma
  # polkit-kde-agent - part of KDE Plasma
  # dolphin - already in kde.nix
  kdePackages.systemsettings  # KDE System Settings (used in Hyprland keybinds)

  # ============================================================================
  # Portal (illogical-impulse-portal)
  # ============================================================================
  # xdg-desktop-portal - already in configuration.nix
  # xdg-desktop-portal-kde - already in configuration.nix
  # xdg-desktop-portal-gtk - already in configuration.nix
  # xdg-desktop-portal-hyprland - already in configuration.nix

  # ============================================================================
  # Python (illogical-impulse-python)
  # ============================================================================
  # clang - build dependency, usually available
  uv                      # Python package manager (used for python venv)
  gtk4                    # GTK4 library
  libadwaita              # Adwaita library
  libsoup_3               # HTTP library (libsoup3)
  libportal-gtk4          # Portal library for GTK4
  gobject-introspection   # GObject introspection

  # ============================================================================
  # Screencapture (illogical-impulse-screencapture)
  # ============================================================================
  # hyprshot - already in image-editing.nix
  slurp                   # Region selector (used in Hyprland and Quickshell)
  swappy                  # Screenshot annotation tool (used in Quickshell)
  tesseract               # OCR engine (used in Quickshell and Hyprland)
  tesseract5              # Tesseract OCR data (tesseract-data-eng equivalent)
  wf-recorder             # Wayland screen recorder (used in Quickshell)

  # ============================================================================
  # Toolkit (illogical-impulse-toolkit)
  # ============================================================================
  upower                  # Power management (used in Quickshell config)
  wtype                   # Wayland text input simulator (used in fuzzel-emoji.sh)
  ydotool                 # Input automation tool (used in Quickshell config)

  # ============================================================================
  # Widgets (illogical-impulse-widgets)
  # ============================================================================
  fuzzel                  # Wayland launcher (used in Hyprland and Quickshell)
  # glib2 - provides gsettings, usually in system
  imagemagick             # Image manipulation (provides magick executable)
  hypridle                # Hyprland idle daemon (used for loginctl to lock session)
  # hyprlock - already in wayland.nix
  hyprpicker              # Color picker (used in Hyprland and Quickshell)
  songrec                 # Music recognition (used in Quickshell)
  translate-shell         # Translation tool (used in Quickshell)
  wlogout                 # Logout menu (used in Hyprland config)
  libqalculate            # Calculator library (provides qalc executable, used in searchbar)
]

