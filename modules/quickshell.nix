{ config, pkgs, lib, gitPkgs ? {}, ... }:
let
  cfg = config.programs.quickshell;

  defaultPackage =
    if gitPkgs ? quickshell then gitPkgs.quickshell
    else if pkgs ? quickshell then pkgs.quickshell
    else throw "No QuickShell package available. Provide one via programs.quickshell.package.";
in {
  options.programs.quickshell = with lib; {
    enable = mkEnableOption "QuickShell Wayland shell";

    package = mkOption {
      type = types.package;
      default = defaultPackage;
      description = "QuickShell package to install and use for sessions.";
    };

    configs = mkOption {
      type = types.attrsOf types.path;
      default = { };
      description = "Mapping of configuration names to directories linked under ~/.config/quickshell/<name>.";
    };
  };

  config = lib.mkIf cfg.enable {
    # Only add package if it's not already wrapped (to avoid collisions)
    # If the package name contains "wrapped", assume it's already wrapped and skip adding it
    home.packages = lib.mkIf (!(lib.hasInfix "wrapped" cfg.package.name)) [ cfg.package ];

    xdg.configFile = lib.mapAttrs' (name: path: {
      name = "quickshell/${name}";
      value = {
        source = path;
        recursive = true;
      };
    }) cfg.configs;
  };
}


