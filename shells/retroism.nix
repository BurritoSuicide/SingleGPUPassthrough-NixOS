{ config, pkgs, lib, ... }:
let
  source = pkgs.fetchFromGitHub {
    owner = "diinki";
    repo = "linux-retroism";
    rev = "b69d8661494e416d071f022a34125c3a8068303d";
    hash = "sha256-pFSmoLwAUZGed48Lxu5+i8EXtyIqbOskeVHqMfgckC4=";
  };

  configDir = "${source}/configs/quickshell";

  packages = with pkgs; [
    quickshell
    nemo
    kitty
    nwg-look
    grim
    slurp
    swappy
    hyprshot
    wl-clipboard
    mako
    dconf
    jq
    socat
    matugen
    material-symbols
  ];
in {
  xdg.configFile."quickshell/retroism".source = configDir;

  # Provide GTK/icon themes for nwg-look if the user wants to enable them manually.
  xdg.dataFile."icons/RetroismIcons".source = "${source}/icon_theme/RetroismIcons";
  xdg.dataFile."themes/Retroism".source = "${source}/gtk_theme/Retroism";

  home.packages = lib.mkBefore packages;

  systemd.user.services."quickshell-retroism" = {
    Unit = {
      Description = "Linux Retroism quickshell session";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };

    Service = {
      Type = "exec";
      ExecStart = "${pkgs.quickshell}/bin/qs -p ${config.home.homeDirectory}/.config/quickshell/retroism";
      Environment = [
        "QT_QPA_PLATFORM=wayland"
        "QML_DISABLE_DISK_CACHE=1"
      ];
      Restart = "on-failure";
    };
  };
}


