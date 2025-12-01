{ pkgs, ... }:

with pkgs; [
  # Game launchers and compatibility
  lutris      # Game manager
  heroic      # Epic Games launcher
  
  # Wine and compatibility layers
  wine        # Windows compatibility layer
  wine64      # 64-bit Wine
  winetricks  # Wine helper
  bottles     # Wine prefix manager
  
  # Gaming utilities
  mangohud    # Vulkan overlay for monitoring
  protonup-qt # Proton-GE updater
  
  # Minecraft server dependencies
  jdk8_headless  # Java 8 JDK (headless) for Minecraft servers like Skyfactory 4
]

