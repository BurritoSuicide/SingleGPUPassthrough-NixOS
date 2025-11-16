{ config, pkgs, lib, dms, ... }:
let
  system = pkgs.stdenv.hostPlatform.system;
  dmsPkgs = {
    dmsCli = dms.packages.${system}.dmsCli;
    dankMaterialShell = dms.packages.${system}.dankMaterialShell;
    dgop = dms.inputs.dgop.packages.${system}.dgop;
  };
in {
  imports = [ dms.homeModules.dankMaterialShell.default ];

  programs.dankMaterialShell = {
    enable = true;
    systemd.enable = false;
    quickshell.package = pkgs.quickshell;
    enableSystemMonitoring = true;
    enableClipboard = true;
    enableVPN = true;
    enableBrightnessControl = true;
    enableColorPicker = true;
    enableDynamicTheming = true;
    enableAudioWavelength = true;
    enableCalendarEvents = false;
    enableSystemSound = true;
  };

  # Ensure CLI and dependencies are present even when the upstream service is disabled.
  home.packages = lib.mkBefore [
    dmsPkgs.dmsCli
    dmsPkgs.dgop
  ];

  systemd.user.services."quickshell-dms" = {
    Unit = {
      Description = "DankMaterialShell quickshell session";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };

    Service = {
      Type = "exec";
      ExecStart = "${dmsPkgs.dmsCli}/bin/dms run --session";
      Environment = [
        "QT_QPA_PLATFORM=wayland"
        "QML_DISABLE_DISK_CACHE=1"
      ];
      Restart = "on-failure";
    };
  };
}


