{ config, pkgs, lib, unstablePkgs, caelestia, noctaliaInput ? null, gitPkgs ? {}, ... }:

let
  hyprctlBin = "${pkgs.hyprland}/bin/hyprctl";
  jqBin = "${pkgs.jq}/bin/jq";
  caelestiaCliBin = "${config.programs.caelestia.cli.package}/bin/caelestia";
in {
  # Import quickshell desktop shells
  imports = [
    ./modules/quickshell.nix
    (let shellsSrc = builtins.path { path = ./shells; name = "shells"; }; in shellsSrc + "/caelestia.nix")
    (let shellsSrc = builtins.path { path = ./shells; name = "shells"; }; in shellsSrc + "/dankmaterial.nix")
    (let shellsSrc = builtins.path { path = ./shells; name = "shells"; }; in shellsSrc + "/noctalia.nix")
  ];

  # Home Manager needs a bit of information about you and the paths it should manage.
  home.username = "scryv";
  home.homeDirectory = "/home/scryv";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  home.stateVersion = "25.05";

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # User packages (stable 25.05)
  home.packages = with pkgs; [
    # Image processing libraries (for caelestia wallpaper support)
    imagemagick
    libjpeg
    libpng

    # KDE applications
    kdePackages.kate

    # Streaming and remote
    sunshine
    moonlight-qt

    # Communication
    thunderbird
    webcord

    # Media tools
    obs-studio
    yt-dlp

    # Gaming
    prismlauncher
    minecraft-server

    # Music streaming
    tidal-dl
    tidal-hifi
    spotify

    # Music production - DAWs
    ardour
    lmms
    qtractor

    # Music production - Synths
    helm
    zynaddsubfx

    # Music production - Audio & MIDI utilities
    carla
    qjackctl
    alsa-utils
    fluidsynth  # MIDI synthesizer for playing piano

    # Music production - Soundfonts
    soundfont-fluid
    soundfont-generaluser
    soundfont-ydp-grand

    #Astrophotography
    siril
	kstars

    # Development
    nodejs
    vscode

    # Image editing
    gimp
    krita
    hyprshot
	
    # Productivity
    obsidian
    libreoffice-qt6

    # 3D
    blender
  ] ++ (lib.optionals (noctaliaInput != null) [
    noctaliaInput.packages.${pkgs.stdenv.hostPlatform.system}.default
  ]) ++ [
    matugen
  ];

  # Ignis/Exo removed

  # You can also manage individual program configurations here
  programs.git = {
    enable = true;
    # userName = "Your Name";
    # userEmail = "your.email@example.com";
  };

  # Optional: Configure other programs with Home Manager
  # programs.bash.enable = true;
  # programs.fish.enable = true;

  # Ignis/Exo removed

  # Caelestia and Noctalia moved to ./shells/*.nix
 
  # Install Hyprland config as real files (not symlinks) into ~/.config/hypr
  home.activation.installHyprConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    set -eu
    dst="$HOME/.config/hypr"
    src=${builtins.path { path = ./hypr; name = "hypr-config-src"; }}

    # If dst is a symlink or directory, remove it to ensure a clean copy
    if [ -L "$dst" ] || [ -d "$dst" ]; then
      rm -rf "$dst"
    fi
    mkdir -p "$(dirname "$dst")"
    cp -a "$src" "$dst"

    # Ensure scripts are executable if present
    if [ -d "$dst/scripts" ]; then
      chmod +x "$dst/scripts/"*.sh 2>/dev/null || true
    fi
  '';

 

  # Exo (Ignis) shell user service (requires Ignis and Exo config)
  systemd.user.services."exo-shell" = {
    Unit = {
      Description = "Exo (Ignis) desktop shell";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      # Exo runs via Ignis; only start if available to avoid restart loops
      ExecStart = "${pkgs.bash}/bin/bash -lc 'if command -v ignis >/dev/null 2>&1; then ignis init; else echo \"Ignis (for Exo) not installed\"; sleep 2; exit 1; fi'";
      Environment = [
        "QT_QPA_PLATFORM=wayland"
      ];
      Restart = "on-failure";
    };
  };

  # Noctalia shell user service
  systemd.user.services."noctalia-shell" = {
    Unit = {
      Description = "Noctalia desktop shell";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      # Try to start via a quickshell profile if present, otherwise a 'noctalia' binary if installed
      ExecStart = "${pkgs.bash}/bin/bash -lc 'if command -v qs >/dev/null 2>&1 && [ -d \"$HOME/.config/quickshell/noctalia\" ]; then qs -p \"$HOME/.config/quickshell/noctalia\"; elif command -v noctalia-shell >/dev/null 2>&1; then noctalia-shell; elif command -v noctalia >/dev/null 2>&1; then noctalia; else echo \"Noctalia not installed\"; sleep 2; exit 1; fi'";
      Environment = [
        "QT_QPA_PLATFORM=wayland"
        "QML_DISABLE_DISK_CACHE=1"
        "PATH=${gitPkgs.quickshell}/bin:/run/wrappers/bin:/nix/var/nix/profiles/default/bin:/run/current-system/sw/bin"
      ];
      Restart = "on-failure";
    };
  };

  # Hypr scripts are included via the directory mapping above

  systemd.user.services.hypr-border-sync = {
    Unit = {
      Description = "Sync Hyprland borders with active shell color scheme";
      After = [ "graphical-session.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash ${config.home.homeDirectory}/.config/hypr/scripts/RainbowBorders.sh";
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };

  systemd.user.paths.hypr-border-sync = {
    Unit = {
      Description = "Watch shell color schemes and active shell state for border sync";
      After = [ "graphical-session.target" ];
    };
    Path = {
      PathChanged = [
        "%h/.local/state/caelestia/scheme.json"
        "%h/.local/state/quickshell/active-shell"
        "%h/.config/gtk-3.0/dank-colors.css"
      ];
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
