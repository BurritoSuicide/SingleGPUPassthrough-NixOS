{ pkgs, ... }:

with pkgs; [
  # Android tools
  android-tools  # Android SDK platform tools (adb, fastboot)
  scrcpy         # Android screen mirroring
]

