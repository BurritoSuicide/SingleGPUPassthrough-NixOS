{ config, pkgs, lib, ... }:

let
  cfg = config.services.selkies;
in {
  options.services.selkies = {
    enable = lib.mkEnableOption "Enable Selkies GStreamer streaming";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.callPackage ../default.nix {};
      description = "Selkies GStreamer package to use.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 8080;
      description = "Port for Selkies WebRTC streaming.";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.selkies = {
      description = "Selkies GStreamer Streaming Service";
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        ExecStart = "${cfg.package}/bin/selkies-gstreamer --port ${toString cfg.port}";
        Restart = "on-failure";
        WorkingDirectory = "/var/lib/selkies";
      };
    };

    networking.firewall.allowedTCPPorts = [ cfg.port ];
  };
}
