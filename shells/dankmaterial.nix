{ config, pkgs, lib, dms, gitPkgs, ... }:
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
    # Set quickshell.package - our quickshell.nix module will skip adding it if it's wrapped
    # The wrapped version from dots-hyprland.nix will be used via PATH
    quickshell.package = gitPkgs.quickshell;
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
  # Note: quickshell is provided by dots-hyprland.nix (wrapped version) to avoid collisions
  home.packages = lib.mkBefore [
    dmsPkgs.dmsCli
    dmsPkgs.dgop
    # qsPkg removed - using wrapped version from dots-hyprland.nix
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
        "PATH=${gitPkgs.quickshell}/bin:/run/wrappers/bin:/nix/var/nix/profiles/default/bin:/run/current-system/sw/bin"
      ];
      Restart = "on-failure";
    };
  };
}


