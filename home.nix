{ config, pkgs, lib, unstablePkgs, caelestia, noctaliaInput ? null, gitPkgs ? {}, ... }:

let
  hyprctlBin = "${pkgs.hyprland}/bin/hyprctl";
  jqBin = "${pkgs.jq}/bin/jq";
  caelestiaCliBin = "${config.programs.caelestia.cli.package}/bin/caelestia";
in {
  # Import quickshell desktop shells
  imports = [
    ./modules/quickshell.nix
    (let shellsSrc = builtins.path { path = ./shells; name = "shells"; }; in shellsSrc + "/caelestia.nix")
    (let shellsSrc = builtins.path { path = ./shells; name = "shells"; }; in shellsSrc + "/dankmaterial.nix")
    (let shellsSrc = builtins.path { path = ./shells; name = "shells"; }; in shellsSrc + "/noctalia.nix")
  ];

  # Home Manager needs a bit of information about you and the paths it should manage.
  home.username = "scryv";
  home.homeDirectory = "/home/scryv";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  home.stateVersion = "25.05";

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # User packages (organized in packages/user/)
  home.packages = let
    userPackagesDir = builtins.path {
      path = ./packages/user;
      name = "user-packages";
      filter = path: type: true;  # Include all files
    };
  in import (toString userPackagesDir + "/default.nix") {
    inherit pkgs unstablePkgs noctaliaInput;
  };

  # You can also manage individual program configurations here
  programs.git = {
    enable = true;
  };

  # Caelestia and Noctalia moved to ./shells/*.nix
 
  # Install Hyprland config as real files (not symlinks) into ~/.config/hypr
  home.activation.installHyprConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    set -eu
    dst="$HOME/.config/hypr"
    src=${builtins.path { path = ./hypr; name = "hypr-config-src"; }}

    # If dst exists, make it writable before removal
    if [ -L "$dst" ] || [ -d "$dst" ]; then
      chmod -R u+w "$dst" 2>/dev/null || true
      rm -rf "$dst"
    fi
    mkdir -p "$(dirname "$dst")"
    cp -a "$src" "$dst"

    # Ensure scripts are executable and directory is writable
    if [ -d "$dst/scripts" ]; then
      chmod +x "$dst/scripts/"*.sh 2>/dev/null || true
    fi
    chmod -R u+w "$dst" 2>/dev/null || true
  '';

  # Update desktop file and MIME databases for proper file associations
  home.activation.updateDesktopDatabase = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if command -v update-desktop-database >/dev/null 2>&1; then
      mkdir -p "$HOME/.local/share/applications"
      update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
    fi
    if command -v update-mime-database >/dev/null 2>&1; then
      mkdir -p "$HOME/.local/share/mime/packages"
      update-mime-database "$HOME/.local/share/mime" 2>/dev/null || true
    fi
  '';

 

  # Hypr scripts are included via the directory mapping above

  systemd.user.services.hypr-border-sync = {
    Unit = {
      Description = "Sync Hyprland borders with active shell color scheme";
      After = [ "graphical-session.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash ${config.home.homeDirectory}/.config/hypr/scripts/animatedborders.sh";
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };

  systemd.user.paths.hypr-border-sync = {
    Unit = {
      Description = "Watch shell color schemes and active shell state for border sync";
      After = [ "graphical-session.target" ];
    };
    Path = {
      PathChanged = [
        "%h/.local/state/caelestia/scheme.json"
        "%h/.local/state/quickshell/active-shell"
        "%h/.config/gtk-3.0/dank-colors.css"
        "%h/.config/noctalia/colors.json"
      ];
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
