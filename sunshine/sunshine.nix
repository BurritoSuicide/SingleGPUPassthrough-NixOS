{ config, lib, pkgs, ... }:

let
  cfg = config.programs.sunshine;
in {
  options.programs.sunshine = {
    enable = lib.mkEnableOption "Enable Sunshine game streaming host";
  };

  config = lib.mkIf cfg.enable {
    # Open necessary firewall ports
    networking.firewall.allowedTCPPortRanges = [
      { from = 47984; to = 48010; }
    ];
    networking.firewall.allowedUDPPortRanges = [
      { from = 47998; to = 48010; }
    ];

    # Wrapper with capability for DRM screen capture
    security.wrappers.sunshine = {
      owner = "root";
      group = "root";
      capabilities = "cap_sys_admin+p";
      source = "${pkgs.sunshine}/bin/sunshine";
    };

    # Systemd user service to run Sunshine
    systemd.user.services.sunshine = {
      description = "Sunshine Game Stream Host";
      after = [ "graphical-session.target" ];
      wantedBy = [ "default.target" ];
      environment = {
        XDG_SESSION_TYPE = "wayland"; # or "x11" if applicable
        DISPLAY = ":0";               # Or pull from login session dynamically
        WAYLAND_DISPLAY = "wayland-0"; # Check your actual value with `echo $WAYLAND_DISPLAY`
      };
      serviceConfig = {
        ExecStart = "${config.security.wrapperDir}/sunshine";
        Restart = "on-failure";
        RestartSec = "5s";
      };
    };
  };
}
