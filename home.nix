{ config, pkgs, lib, unstablePkgs, caelestia, noctaliaInput ? null, gitPkgs ? {}, illogicalImpulse ? null, ... }:

{
  # ============================================================================
  # Imports
  # ============================================================================
  # Import quickshell desktop shells
  # Consolidate shell imports to avoid multiple builtins.path calls
  # Note: illogical-impulse module must be imported BEFORE the shell config that uses its options
  imports = [
    ./modules/quickshell.nix
  ] ++ lib.optionals (illogicalImpulse != null) [
    # Import a wrapper module that excludes the quickshell config to avoid conflicts
    # with our other quickshell configs (caelestia, noctalia, dms)
    (import ./modules/illogical-impulse-wrapper.nix { inherit illogicalImpulse; })
  ] ++ (let shellsSrc = builtins.path { path = ./shells; name = "shells"; }; in [
    (shellsSrc + "/caelestia.nix")
    (shellsSrc + "/dankmaterial.nix")
    (shellsSrc + "/noctalia.nix")
    (shellsSrc + "/illogical-impulse.nix")
  ]);

  # ============================================================================
  # Home Manager Basic Configuration
  # ============================================================================
  home.username = "scryv";
  home.homeDirectory = "/home/scryv";
  home.stateVersion = "25.05";
  programs.home-manager.enable = true;

  # ============================================================================
  # User Packages
  # ============================================================================
  # User packages (organized in packages/user/)
  # See packages/user/README.md for package organization
  home.packages = let
    userPackagesDir = builtins.path {
      path = ./packages/user;
      name = "user-packages";
      filter = path: type: true;  # Include all files
    };
    userPkgs = import (toString userPackagesDir + "/default.nix") {
      inherit pkgs unstablePkgs noctaliaInput;
    };
    # Ensure quickshell is available in PATH for the settings button to work
    # The packagesModule doesn't add it (it's commented out), and we excluded quickshell.nix
    # This is needed because the settings button uses Quickshell.execDetached(["qs", "-p", ...])
    # Use the same quickshell package as the service (from gitPkgs)
    quickshellPkg = lib.optionals (illogicalImpulse != null && gitPkgs ? quickshell) [
      gitPkgs.quickshell
    ];
  in userPkgs ++ quickshellPkg;

  # ============================================================================
  # Program Configuration
  # ============================================================================
  programs.git = {
    enable = true;
  };

  # ============================================================================
  # Home Manager Activation Scripts
  # ============================================================================
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

  # ============================================================================
  # Systemd User Services
  # ============================================================================
  # Hypr scripts are included via the directory mapping above

  # Service to sync Hyprland borders with active shell color scheme
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
        "%h/.config/quickshell/ii"
      ];
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };

  # ============================================================================
  # Illogical Impulse (end-4-dots) Shell Configuration
  # ============================================================================
  # Configure illogical-impulse if the module is available
  # Note: The module is imported above, so its options are available here
  illogical-impulse = lib.mkIf (illogicalImpulse != null) {
    enable = true;
    hyprland = {
      # Use our existing Hyprland package (don't override)
      package = pkgs.hyprland;
      xdgPortalPackage = pkgs.xdg-desktop-portal-hyprland;
      ozoneWayland.enable = true;
      # Use default monitor configuration
      monitor = [ ",preferred,auto,1" ];
    };
    # Enable dotfiles components (optional - adjust as needed)
    dotfiles = {
      kitty.enable = false;  # We may already have kitty configured
      fish.enable = false;   # We may already have fish configured
      starship.enable = false;  # We may already have starship configured
    };
  };

  # Disable the hyprland module part since we manage Hyprland separately
  # The module's hyprland.nix would try to enable wayland.windowManager.hyprland
  # which conflicts with our system-level Hyprland configuration
  wayland.windowManager.hyprland.enable = lib.mkIf (illogicalImpulse != null) (lib.mkForce false);

  # Install the "ii" quickshell config directory
  # We use a wrapper module that excludes the quickshell.nix part to avoid conflicts
  # with our other quickshell configs (caelestia, noctalia, dms)
  # Instead, we manually set up just the "ii" config here
  xdg.configFile."quickshell/ii" = lib.mkIf (illogicalImpulse != null) {
    source = "${illogicalImpulse.inputs.illogical-impulse-dotfiles}/.config/quickshell/ii";
    recursive = true;
  };


  # Illogical Impulse shell user service
  systemd.user.services."quickshell-ii" = lib.mkIf (illogicalImpulse != null) {
    Unit = {
      Description = "Illogical Impulse (end-4-dots) Quickshell session";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "exec";
      # Use the quickshell from gitPkgs (which is the wrapped version if available)
      # The illogical-impulse module should have set up the config at ~/.config/quickshell
      # We need to set up Qt environment variables to include qt5compat for Qt5Compat.GraphicalEffects
      ExecStart = let
        # Qt packages needed for illogical-impulse (including qt5compat for Qt5Compat.GraphicalEffects)
        qtPackages = with unstablePkgs.kdePackages; [
          qt5compat
          qtbase
          qtdeclarative
          qtmultimedia
          qtpositioning
          qtquicktimeline
          qtsensors
          qtsvg
          qtwayland
          qtimageformats
          qttools
          qttranslations
          qtvirtualkeyboard
          syntax-highlighting
        ];
        qmlPath = lib.makeSearchPath "lib/qt-6/qml" qtPackages;
        pluginPath = lib.makeSearchPath "lib/qt-6/plugins" [
          unstablePkgs.kdePackages.qtbase
          unstablePkgs.kdePackages.qtdeclarative
          unstablePkgs.kdePackages.qtwayland
          unstablePkgs.kdePackages.qt5compat
        ];
      in "${pkgs.bash}/bin/bash -c 'export QML2_IMPORT_PATH=\"${qmlPath}:$QML2_IMPORT_PATH\"; export QT_PLUGIN_PATH=\"${pluginPath}:$QT_PLUGIN_PATH\"; exec ${gitPkgs.quickshell}/bin/qs -p ${config.home.homeDirectory}/.config/quickshell/ii'";
      Environment = [
        "QT_QPA_PLATFORM=wayland"
        "QML_DISABLE_DISK_CACHE=1"
        "qsConfig=ii"
        "ILLOGICAL_IMPULSE_VIRTUAL_ENV=${config.home.homeDirectory}/.local/state/quickshell/.venv"
      ];
      Restart = "on-failure";
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
