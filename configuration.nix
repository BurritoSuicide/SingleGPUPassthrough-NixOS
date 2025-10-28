# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running 'nixos-help').

{ config, pkgs, lib, unstablePkgs, gitPkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./sunshine/sunshine.nix
    ./gpu-passthrough.nix
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixos";
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/New_York";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  swapDevices = [{ device = "/swapfile"; size = 16 * 1024; }];

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the KDE Plasma Desktop Environment.
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  # Enable Hyprland
  programs.hyprland.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  services.pipewire = {
    enable = true;
    audio.enable = true;
    pulse.enable = true;
    jack.enable = false;
    alsa.enable = true;
    alsa.support32Bit = true;

    wireplumber.enable = true;

    extraConfig.pipewire = {
      "context.properties" = {
        "link.max-buffers" = 64;
        "log.level" = 2;
        "default.clock.rate" = 48000;
        "default.clock.quantum" = 1024;
        "default.clock.min-quantum" = 32;
        "default.clock.max-quantum" = 2048;
      };
    };
  };

  services.udev.packages = [ pkgs.android-udev-rules ];
  programs.adb.enable = true;

  # Define a user account. Don't forget to set a password with 'passwd'.
  users.users.scryv = {
    isNormalUser = true;
    description = "scryv";
    extraGroups = [ "networkmanager" "wheel" "libvirtd" "sunshine" "scryv" "audio" "video" "adbusers" "plugdev"];
    shell = pkgs.fish;
  };

  # Install firefox.
  programs.firefox.enable = true;
  programs.fish.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  nixpkgs.config = {
    permittedInsecurePackages = [ "ventoy-qt5-1.1.05" ];
    allowUnsupportedSystem = true;
    allowBroken = true;
    allow32bit = true;
  };

  nixpkgs.overlays = [
    (final: prev: {
      python3 = prev.python312;
      python3Packages = prev.python312Packages;
    })
  ];

  # System packages (stable 25.05)
  environment.systemPackages = with pkgs; [

    # Python with packages
    (python3.withPackages (ps: with ps; [
      pip
      virtualenv
      flask
      requests
      pyperclip
      textual
      pypresence
    ]))

    # System utilities
    fastfetch
    btop
    caligula
    ventoy-full-qt
    nix-update
    psutils
    sysstat
    eza
    vim
    wget
    git
    micro
    pciutils
    fd
    tree
    curl
    gawk
    jq
    fzf
    bc

    # Monitoring
    radeontop
    amdgpu_top
    gcalcli

    # GPU Tuning
    e2fsprogs
    lact

    # Disk Management
    ncdu

    # Wayland/Hyprland
    wofi
    kitty
    nwg-look
    libnotify
    brightnessctl
    playerctl
    pamixer
    swww
    hyprpaper
    xdg-utils
    xdgmenumaker
    bemenu

    # Media
    mpv
    mpvpaper
    ffmpeg
    socat
    wireplumber
    sassc
    pavucontrol
    vlc

    # Electronics
    arduino-ide

    # Gaming
    lutris
    wine
    wine64
    winetricks
    bottles
    mangohud
    protonup-qt
    heroic

    # .NET
    dotnet-sdk_8
    dotnet-runtime_8
    dotnet-aspnetcore_8

    # Remoting
    xorg.xrandr
    openssl

    # Phone streaming
    android-tools
    scrcpy

  ] ++ [
    # Unstable packages
    unstablePkgs.kando
    unstablePkgs.waybar
    unstablePkgs.wayvnc
    unstablePkgs.app2unit
    unstablePkgs.ddcutil
    unstablePkgs.libcava
  ] ++ [
    # Git-built packages
    gitPkgs.quickshell
  ];

  # Graphics support
  hardware.graphics.enable = true;

  # Remoting
  services.openssh.enable = true;
  services.tailscale.enable = true;

  services.cockpit = {
    enable = true;
    openFirewall = true;
  };

  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true;
    openFirewall = true;
  };

  # Linux Gaming
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    gamescopeSession.enable = true;
  };

  # Flatpak
  services.flatpak.enable = true;

  environment.sessionVariables.XDG_DATA_DIRS = lib.mkAfter [
    "/var/lib/flatpak/exports/share"
    "${config.users.users.scryv.home}/.local/share/flatpak/exports/share"
  ];

  security.polkit.enable = true;


  security.sudo.enable = true;
  security.sudo.extraConfig = ''
    scryv ALL=(ALL) NOPASSWD: /run/current-system/sw/bin/radeontop
  '';

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
    nerd-fonts.hack
    papirus-icon-theme
  ];


  # Configure GPU passthrough for virtualization. See gpu-passthrough.nix for more information.
  services.gpu-passthrough = {
    enable = true;
    vmName = "win10";  # Name of your VM
    gpuPciId = "0000:07:00.0";  # From your lspci output
    audioPciId = "0000:07:00.1";  # From your lspci output
    gpuIommuIds = [
      "1002:731f"  # RX 5600/5700 XT GPU
      "1002:ab38"  # Navi 10 HDMI Audio
    ];
    hugepages = null;  #Disabled initially
  };

  virtualisation.kvmgt.enable = true;

  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [ 5900 ];

  system.stateVersion = "25.05";
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
}
