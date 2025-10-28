{ config, pkgs, unstablePkgs, caelestia, ... }:

{
  # Import caelestia-shell home-manager module
  imports = [
    caelestia.homeManagerModules.default
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
  ];

  # You can also manage individual program configurations here
  programs.git = {
    enable = true;
    # userName = "Your Name";
    # userEmail = "your.email@example.com";
  };

  # Optional: Configure other programs with Home Manager
  # programs.bash.enable = true;
  # programs.fish.enable = true;

  # Caelestia shell configuration
  programs.caelestia = {
    enable = true;
    systemd = {
      enable = false; # if you prefer starting from your compositor
      target = "graphical-session.target";
      environment = [];
    };
    settings = {
      bar.status = {
        showBattery = false;
      };
      paths.wallpaperDir = "~/Images";
    };
    cli = {
      enable = true; # Also add caelestia-cli to path
      settings = {
        theme.enableGtk = false;
      };
    };
  };
}
