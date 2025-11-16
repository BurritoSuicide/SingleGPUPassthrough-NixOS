{ config, pkgs, lib, ... }:
let
  source = pkgs.fetchFromGitHub {
    owner = "end-4";
    repo = "dots-hyprland";
    rev = "37c1d9cf61018c99fbba61f043d43ed49c45e7f2";
    hash = "sha256-U3XvUZdN+/xvZH5LlpGCCXbg62fjErvx7Wr6w/3om2o=";
    fetchSubmodules = true;
  };

  configDir = "${source}/dots/.config/quickshell/ii";

  packages = with pkgs; [
    quickshell
    cliphist
    wl-clipboard
    hyprshot
    slurp
    swappy
    brightnessctl
    ddcutil
    playerctl
    matugen
    kitty
    foot
    jq
    ripgrep
    curl
    wget
    bc
    eza
    pipewire
    wireplumber
    lxqt.pavucontrol-qt
    hyprsunset
    upower
    ydotool
    wtype
    rsync
    xdg-user-dirs
    starship
    material-symbols
    nerd-fonts.jetbrains-mono
    rubik
    adw-gtk3
    darkly
    networkmanager
    kdePackages.plasma-nm
    kdePackages.bluedevil
    kdePackages.systemsettings
    gsettings-desktop-schemas
    kdePackages.kdialog
    kdePackages.qt6ct
  ];
in {
  xdg.configFile."quickshell/ii".source = configDir;

  home.packages = lib.mkBefore packages;

  systemd.user.services."quickshell-ii" = {
    Unit = {
      Description = "Illogical Impulse Quickshell session";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };

    Service = {
      Type = "exec";
      ExecStart = "${pkgs.quickshell}/bin/qs -c ii";
      Environment = [
        "QT_QPA_PLATFORM=wayland"
        "QML_DISABLE_DISK_CACHE=1"
      ];
      Restart = "on-failure";
    };
  };
}


