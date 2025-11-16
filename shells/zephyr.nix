{ config, pkgs, lib, gitPkgs, ... }:
let
  source = pkgs.fetchFromGitHub {
    owner = "flickowoa";
    repo = "zephyr";
    rev = "d2e9782b14fd594bf855c21ffc6c173135e12691";
    hash = "sha256-asyxVBPsLH5T3NOkWjBSoxCBEhZtTtLM/EZmZABYu1o=";
    fetchSubmodules = false;
  };

  configDir = "${source}/quickshell";

  packages = with pkgs; [
    # Basic utilities that might be needed
    jq
    gitPkgs.quickshell  # Add quickshell to PATH
  ];
in {
  xdg.configFile."quickshell/zephyr".source = configDir;

  home.packages = lib.mkBefore packages;

  systemd.user.services."quickshell-zephyr" = {
    Unit = {
      Description = "Zephyr Quickshell session";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };

    Service = {
      Type = "exec";
      ExecStart = "${gitPkgs.quickshell}/bin/qs -p ${config.home.homeDirectory}/.config/quickshell/zephyr";
      Environment = [
        "QT_QPA_PLATFORM=wayland"
        "QML_DISABLE_DISK_CACHE=1"
      ];
      Restart = "on-failure";
    };
  };
}

