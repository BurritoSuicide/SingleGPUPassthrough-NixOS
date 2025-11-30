# Wrapper module for illogical-impulse that excludes the quickshell config
# to avoid conflicts with other quickshell configs (caelestia, noctalia, dms)
{ illogicalImpulse, ... }:

let
  # Get the module source path
  moduleSource = illogicalImpulse.outPath or illogicalImpulse;
  # Import all modules except quickshell.nix
  optionsModule = import "${moduleSource}/modules/options.nix" illogicalImpulse.inputs.illogical-impulse-dotfiles;
  hyprlandModule = import "${moduleSource}/modules/hyprland.nix" illogicalImpulse.inputs.illogical-impulse-dotfiles illogicalImpulse.inputs;
  packagesModule = import "${moduleSource}/modules/packages.nix" illogicalImpulse.inputs;
  # Skip quickshell.nix to avoid conflicts
in
{
  imports = [
    optionsModule
    hyprlandModule
    packagesModule
    # quickshell.nix is intentionally excluded to avoid replacing the entire
    # ~/.config/quickshell directory, which conflicts with caelestia, noctalia, and dms configs
  ];
}

