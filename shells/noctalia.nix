{ config, pkgs, lib, noctaliaInput ? null, gitPkgs ? {}, ... }:
{
  imports = lib.optionals (noctaliaInput != null) [ noctaliaInput.homeModules.default ];

  programs.noctalia-shell = lib.mkIf (noctaliaInput != null) {
    enable = true;
  };

  # Noctalia shell user service
  systemd.user.services."noctalia-shell" = {
    Unit = {
      Description = "Noctalia desktop shell";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.bash}/bin/bash -lc 'if command -v qs >/dev/null 2>&1 && [ -d \"$HOME/.config/quickshell/noctalia\" ]; then qs -p \"$HOME/.config/quickshell/noctalia\"; elif command -v noctalia-shell >/dev/null 2>&1; then noctalia-shell; elif command -v noctalia >/dev/null 2>&1; then noctalia; else echo \"Noctalia not installed\"; sleep 2; exit 1; fi'";
      Environment = [
        "QT_QPA_PLATFORM=wayland"
        "QML_DISABLE_DISK_CACHE=1"
        "PATH=${gitPkgs.quickshell}/bin:/run/wrappers/bin:/nix/var/nix/profiles/default/bin:/run/current-system/sw/bin"
      ];
      Restart = "on-failure";
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}


