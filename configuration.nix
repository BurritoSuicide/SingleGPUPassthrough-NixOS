# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running 'nixos-help').

{ config, pkgs, lib, unstablePkgs, gitPkgs, ... }:

{
  # ============================================================================
  # Imports
  # ============================================================================
  imports = [
    ./hardware-configuration.nix
    ./sunshine/sunshine.nix
    ./gpu-passthrough.nix
  ];

  # ============================================================================
  # Boot Configuration
  # ============================================================================
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # ============================================================================
  # Networking
  # ============================================================================
  networking.hostName = "nixos";
  networking.networkmanager.enable = true;

  # ============================================================================
  # Localization
  # ============================================================================
  # Required for QtPositioning (used by some quickshell configurations)
  services.geoclue2.enable = true;
  time.timeZone = "America/New_York";
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

  # ============================================================================
  # Display and Desktop Environment
  # ============================================================================
  # Enable the X11 windowing system (required for some applications)
  services.xserver.enable = true;

  # KDE Plasma Desktop Environment
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  # Hyprland Wayland compositor
  programs.hyprland.enable = true;

  # XDG Desktop Portal for MIME type handling and file associations
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-hyprland
      xdg-desktop-portal-gtk
      kdePackages.xdg-desktop-portal-kde
    ];
    configPackages = [ pkgs.xdg-desktop-portal-hyprland ];
  };

  # Keyboard configuration
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # ============================================================================
  # Audio and Printing
  # ============================================================================
  # Printing support
  services.printing.enable = true;

  # PipeWire audio system
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

  # ============================================================================
  # Android Development
  # ============================================================================
  services.udev.packages = [ pkgs.android-udev-rules ];
  programs.adb.enable = true;

  # ============================================================================
  # User Configuration
  # ============================================================================
  users.users.scryv = {
    isNormalUser = true;
    description = "scryv";
    extraGroups = [ "networkmanager" "wheel" "libvirtd" "sunshine" "scryv" "audio" "video" "adbusers" "plugdev" "kvm" "input"];
    shell = pkgs.fish;
  };

  # ============================================================================
  # System Programs
  # ============================================================================
  programs.firefox.enable = true;
  programs.fish.enable = true;

  # ============================================================================
  # Package Management
  # ============================================================================
  # Nixpkgs configuration moved to flake.nix for flake-based configuration
  nixpkgs.overlays = [
    (final: prev: {
      python3 = prev.python312;
      python3Packages = prev.python312Packages;
    })
  ];

  # System packages (organized in packages/system/)
  # See packages/system/README.md for package organization
  environment.systemPackages = import ./packages/system/default.nix {
    inherit pkgs unstablePkgs;
  };

  # ============================================================================
  # Hardware Configuration
  # ============================================================================
  hardware.graphics.enable = true;

  # ============================================================================
  # Remote Access Services
  # ============================================================================
  services.openssh.enable = true;
  services.tailscale.enable = true;

  # ============================================================================
  # System Services
  # ============================================================================
  # Web-based system management
  services.cockpit = {
    enable = true;
    openFirewall = true;
  };

  # Game streaming host (Sunshine)
  # Note: The sunshine module in ./sunshine/sunshine.nix provides a user service.
  # This system service is kept for system-level configuration (firewall, capabilities).
  # The actual Sunshine daemon runs as a user service via the module.
  # A newer version of sunshine is also available via unstable packages.
  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true;
    openFirewall = true;
  };

  # ============================================================================
  # Gaming
  # ============================================================================
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    gamescopeSession.enable = true;
  };

  # ============================================================================
  # Flatpak Support
  # ============================================================================
  services.flatpak.enable = true;
  environment.sessionVariables.XDG_DATA_DIRS = lib.mkAfter [
    "/var/lib/flatpak/exports/share"
    "${config.users.users.scryv.home}/.local/share/flatpak/exports/share"
  ];

  # ============================================================================
  # Security and Permissions
  # ============================================================================
  security.polkit.enable = true;
  security.sudo.enable = true;
  security.sudo.extraConfig = ''
    scryv ALL=(ALL) NOPASSWD: /run/current-system/sw/bin/radeontop
  '';

  # ============================================================================
  # Fonts
  # ============================================================================
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
    nerd-fonts.hack
    papirus-icon-theme
  ];

  # ============================================================================
  # Virtualization and GPU Passthrough
  # ============================================================================
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
    hugepages = null;  # Disabled initially
  };
  virtualisation.kvmgt.enable = true;
  
  # ============================================================================
  # MJPG Configuration
  # ============================================================================
  # Live feed - service is installed but not started automatically on boot
  # Start manually with: sudo systemctl start mjpg-streamer.service
  # Stop with: sudo systemctl stop mjpg-streamer.service
  # Enable/disable auto-start with: sudo systemctl enable/disable mjpg-streamer.service
  services.mjpg-streamer = {
      enable = true;  # Create the service
      inputPlugin = "input_uvc.so -d /dev/video0 -r 640x480 -f 15";
      outputPlugin = "output_http.so -p 8081 -w @www@";
    };
  
  # Override the service to not start automatically on boot
  # The service will be available via systemctl but won't auto-start
  systemd.services.mjpg-streamer.wantedBy = lib.mkForce [ ];

  # ============================================================================
  # Firewall Configuration
  # ============================================================================
  # Note: Most services (cockpit, sunshine, tailscale, steam) handle their own firewall rules
  # via their respective service modules. Only explicitly list ports not handled by services.
  networking.firewall.allowedTCPPorts = [ 5900 8081 ];  # VNC port (if using VNC server)

  # ============================================================================
  # Nix Configuration
  # ============================================================================
  system.stateVersion = "25.05";
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    allow-import-from-derivation = true;
    pure-eval = false;
  };
}
