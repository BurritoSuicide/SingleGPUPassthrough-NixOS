# Package Organization

This directory contains organized package definitions separated by system and user packages.

## Structure

```
packages/
├── system/          # System-wide packages (installed via configuration.nix)
│   ├── default.nix  # Aggregates all system packages
│   ├── python.nix
│   ├── sysutil.nix
│   ├── monitoring.nix
│   ├── gpu.nix
│   ├── disk.nix
│   ├── wayland.nix
│   ├── media.nix
│   ├── electronics.nix
│   ├── gaming.nix
│   ├── dotnet.nix
│   ├── remoting.nix
│   ├── phone.nix
│   ├── ai.nix
│   └── unstable.nix
└── user/            # User packages (installed via home.nix)
    ├── default.nix  # Aggregates all user packages
    ├── image-libs.nix
    ├── kde.nix
    ├── streaming.nix
    ├── communication.nix
    ├── media-tools.nix
    ├── gaming.nix
    ├── music-streaming.nix
    ├── music-production.nix
    ├── astro.nix
    ├── dev.nix
    ├── image-editing.nix
    ├── productivity.nix
    ├── 3d.nix
    └── theming.nix
```

## System Packages

### python.nix
Python runtime and common packages (pip, virtualenv, flask, requests, etc.)

### sysutil.nix
System utilities: fastfetch, btop, caligula, ventoy, nix-update, file/text utilities (eza, fd, tree, vim, micro), network utilities (wget, curl), text processing (gawk, jq, fzf, bc), git, pciutils, busybox

### monitoring.nix
System monitoring tools: radeontop, amdgpu_top, gcalcli, libqalculate

### gpu.nix
GPU tuning: lact (Linux AMD GPU Controller)

### disk.nix
Disk and filesystem utilities: e2fsprogs, ncdu

### wayland.nix
Wayland/Hyprland related packages: hyprlock, wofi, bemenu, kitty, foot, brightnessctl, playerctl, pamixer, libnotify, swww, hyprpaper, nwg-look, xdg-utils, starship, and unstable packages (kando, waybar, wayvnc, app2unit, ddcutil)

### media.nix
Media players and processing: mpv, mpvpaper, vlc, ffmpeg, wireplumber, pavucontrol, sassc, socat

### electronics.nix
Electronics development: arduino-ide

### gaming.nix
Gaming tools: lutris, heroic, wine, winetricks, bottles, mangohud, protonup-qt

### dotnet.nix
.NET framework: dotnet-sdk_8, dotnet-runtime_8, dotnet-aspnetcore_8

### remoting.nix
Remote access: xorg.xrandr, openssl

### phone.nix
Android tools: android-tools, scrcpy

### ai.nix
AI/ML tools: ollama

### unstable.nix
Unstable packages that don't fit other categories: libcava, code-cursor

## User Packages

### image-libs.nix
Image processing libraries: imagemagick, libjpeg, libpng

### kde.nix
KDE applications: kate, dolphin, qt6ct, kdegraphics-thumbnailers, ffmpegthumbs

### streaming.nix
Game streaming: sunshine, moonlight-qt

### communication.nix
Communication tools: thunderbird, webcord

### media-tools.nix
Media tools: obs-studio, yt-dlp

### gaming.nix
Gaming: prismlauncher, minecraft-server

### music-streaming.nix
Music streaming: tidal-dl, tidal-hifi, spotify

### music-production.nix
Music production: DAWs (ardour, lmms, qtractor), synths (helm, zynaddsubfx), audio utilities (carla, qjackctl, alsa-utils, fluidsynth), soundfonts

### astro.nix
Astrophotography: siril, kstars

### dev.nix
Development tools: nodejs, vscode

### image-editing.nix
Image editing: gimp, krita, hyprshot

### productivity.nix
Productivity: obsidian, libreoffice-qt6

### 3d.nix
3D modeling: blender

### theming.nix
Theming utilities: matugen

## Usage

The packages are automatically imported in:
- `configuration.nix` → imports `packages/system/default.nix`
- `home.nix` → imports `packages/user/default.nix`

To add a new package:
1. Find the appropriate category file
2. Add the package to that file
3. The package will be automatically included via the default.nix aggregator

