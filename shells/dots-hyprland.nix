{ config, pkgs, lib, gitPkgs, unstablePkgs, ... }:
let
  source = pkgs.fetchFromGitHub {
    owner = "end-4";
    repo = "dots-hyprland";
    rev = "37c1d9cf61018c99fbba61f043d43ed49c45e7f2";
    hash = "sha256-3kOCz8RrcQCqO2hSI0iWzIQhYixPNYFdMyFWWBmJghY=";
    fetchSubmodules = true;
  };

  configDir = pkgs.runCommand "illogical-impulse-config" { } ''
    mkdir -p $out
    cp -r ${source}/dots/.config/quickshell/ii/. $out/
    chmod -R u+rwX $out

    sed -i '/import qs.modules.ii.cheatsheet/d' $out/shell.qml
    sed -i '/import qs.modules.ii.overview/d' $out/shell.qml
    sed -i '/import qs.modules.ii.regionSelector/d' $out/shell.qml
    sed -i '/import qs.modules.ii.overlay/d' $out/shell.qml
    # Keep sidebars - they are needed for AI and other features
    # sed -i '/import qs.modules.ii.sidebarLeft/d' $out/shell.qml
    # sed -i '/import qs.modules.ii.sidebarRight/d' $out/shell.qml
    sed -i '/import qs.modules.waffle.background/d' $out/shell.qml
    sed -i '/import qs.modules.waffle.bar/d' $out/shell.qml

    sed -i '/identifier: "iiCheatsheet"/d' $out/shell.qml
    sed -i '/identifier: "iiOverview"/d' $out/shell.qml
    sed -i '/identifier: "iiRegionSelector"/d' $out/shell.qml
    sed -i '/identifier: "iiOverlay"/d' $out/shell.qml
    # Keep sidebars - they are needed for AI and other features
    # sed -i '/identifier: "iiSidebarLeft"/d' $out/shell.qml
    # sed -i '/identifier: "iiSidebarRight"/d' $out/shell.qml
    sed -i '/identifier: "wBar"/d' $out/shell.qml
    sed -i '/identifier: "wBackground"/d' $out/shell.qml

    sed -i 's/property list<string> families: \["ii", "waffle"\]/property list<string> families: \["ii"\]/' $out/shell.qml
    ${pkgs.perl}/bin/perl -0pi -e 's/property var panelFamilies: \(\{\n        "ii": \[.*?\n    \}\)/property var panelFamilies: ({\n        "ii": ["iiBar", "iiBackground", "iiDock", "iiLock", "iiMediaControls", "iiNotificationPopup", "iiOnScreenDisplay", "iiOnScreenKeyboard", "iiPolkit", "iiReloadPopup", "iiScreenCorners", "iiSessionScreen", "iiSidebarLeft", "iiSidebarRight", "iiVerticalBar", "iiWallpaperSelector"]\n    })/s' $out/shell.qml
  '';

  # Wrap quickshell with proper Qt module paths
  # Now that quickshell is built against unstable Qt, use unstable Qt packages throughout
  # This ensures compatibility with Qt.labs.synchronizer (6.10+)
  unstableQtPackages = [
    unstablePkgs.kdePackages.qtpositioning
    unstablePkgs.kdePackages.qtbase
    unstablePkgs.kdePackages.qtdeclarative  # Has Qt.labs.synchronizer in 6.10+
    unstablePkgs.kdePackages.qtmultimedia
    unstablePkgs.kdePackages.qtsensors
    unstablePkgs.kdePackages.qtsvg
    unstablePkgs.kdePackages.qtwayland
    unstablePkgs.kdePackages.qt5compat
    unstablePkgs.kdePackages.qtimageformats
    unstablePkgs.kdePackages.qtquicktimeline
    unstablePkgs.kdePackages.qttools
    unstablePkgs.kdePackages.qtvirtualkeyboard
    unstablePkgs.kdePackages.qtwebsockets
    unstablePkgs.kdePackages.qtlocation
    unstablePkgs.kdePackages.qtscxml
  ];
  # Create wrapper scripts that set Qt environment variables and call the original quickshell
  # This avoids collisions if gitPkgs.quickshell is already wrapped
  qsWrapper = pkgs.writeShellScriptBin "qs" ''
    #!/usr/bin/env bash
    # Use unstable Qt packages (matching quickshell's build)
    export QML2_IMPORT_PATH="${lib.makeSearchPath "lib/qt-6/qml" unstableQtPackages}:''${QML2_IMPORT_PATH:-}"
    export QT_PLUGIN_PATH="${lib.makeSearchPath "lib/qt-6/plugins" [
      unstablePkgs.kdePackages.qtbase
      unstablePkgs.kdePackages.qtdeclarative
      unstablePkgs.kdePackages.qtwayland
    ]}:''${QT_PLUGIN_PATH:-}"
    exec "${gitPkgs.quickshell}/bin/qs" "$@"
  '';
  quickshellWrapper = pkgs.writeShellScriptBin "quickshell" ''
    #!/usr/bin/env bash
    # Use unstable Qt packages (matching quickshell's build)
    export QML2_IMPORT_PATH="${lib.makeSearchPath "lib/qt-6/qml" unstableQtPackages}:''${QML2_IMPORT_PATH:-}"
    export QT_PLUGIN_PATH="${lib.makeSearchPath "lib/qt-6/plugins" [
      unstablePkgs.kdePackages.qtbase
      unstablePkgs.kdePackages.qtdeclarative
      unstablePkgs.kdePackages.qtwayland
    ]}:''${QT_PLUGIN_PATH:-}"
    exec "${gitPkgs.quickshell}/bin/quickshell" "$@"
  '';
  # Use just the wrappers - don't include gitPkgs.quickshell to avoid collisions
  # The wrappers will call the original quickshell which should be available via PATH
  # or we need to ensure gitPkgs.quickshell is in the closure separately
  qsPkg = pkgs.symlinkJoin {
    name = "quickshell-ii-wrappers";
    paths = [ qsWrapper quickshellWrapper ];
  };

  packages = with pkgs; [
    cliphist
    wl-clipboard
    hyprshot
    slurp
    swappy
    brightnessctl
    ddcutil
    playerctl
    matugen
    kitty
    foot
    jq
    ripgrep
    curl
    wget
    bc
    eza
    pipewire
    wireplumber
    lxqt.pavucontrol-qt
    hyprsunset
    upower
    ydotool
    wtype
    rsync
    xdg-user-dirs
    starship
    material-symbols
    nerd-fonts.jetbrains-mono
    rubik
    adw-gtk3
    darkly
    networkmanager
    kdePackages.plasma-nm
    kdePackages.bluedevil
    kdePackages.systemsettings
    gsettings-desktop-schemas
    kdePackages.kdialog
    kdePackages.qt6ct
    # Note: Unstable Qt packages are NOT added to home.packages to avoid collisions
    # with stable Qt packages used by other applications (kate, libreoffice-qt6, etc.)
    # They are only available through the wrapped quickshell's environment variables
  ];
in {
  xdg.configFile."quickshell/ii".source = configDir;

  # Add only the wrappers - the original quickshell will be in the closure via the wrapper's store path reference
  # This avoids collisions since only the wrappers provide the binaries
  home.packages = lib.mkBefore (packages ++ [ qsPkg ]);

  systemd.user.services."quickshell-ii" = {
    Unit = {
      Description = "Illogical Impulse Quickshell session";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };

    Service = {
      Type = "exec";
      ExecStart = "${qsPkg}/bin/qs -p ${config.home.homeDirectory}/.config/quickshell/ii";
      Environment = [
        "QT_QPA_PLATFORM=wayland"
        "QML_DISABLE_DISK_CACHE=1"
        "qsConfig=ii"
      ];
      Restart = "on-failure";
    };
  };
}


