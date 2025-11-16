{ config, lib, pkgs, caelestia, ... }:
let
  caelestiaCliBin = "${config.programs.caelestia.cli.package}/bin/caelestia";
in {
  imports = [ caelestia.homeManagerModules.default ];

  programs.caelestia = {
    enable = true;
    systemd = {
      enable = true;
      target = "graphical-session.target";
      environment = [];
    };
    settings = {
      bar.status = { showBattery = false; };
      paths.wallpaperDir = "~/Images";
      general.idle = {
        lockBeforeSleep = false;
        inhibitWhenAudio = true;
        timeouts = [];
      };
    };
    cli = {
      enable = true;
      settings = {
        theme.enableGtk = false;
      };
    };
  };

  xdg.configFile."quickshell/caelestia/modules/bar/components/OsIcon.qml" = {
    force = true;
    text = ''
import Quickshell
import QtQuick
import qs.components.effects
import qs.services
import qs.config
import qs.utils

ColouredIcon {
    id: root

    source: SysInfo.osLogo
    implicitSize: Appearance.font.size.large * 1.2
    colour: Colours.palette.m3tertiary

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton
        onClicked: Quickshell.execDetached(["${caelestiaCliBin}", "shell", "drawers", "toggle", "launcher"])
    }
}
    '';
  };
}


