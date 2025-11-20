{ pkgs, ... }:

with pkgs; [
  # System information and monitoring
  fastfetch  # System information fetcher
  btop       # Resource monitor
  caligula   # System monitor
  
  # USB/Disk utilities
  ventoy-full-qt  # USB bootable disk creator
  
  # Nix utilities
  nix-update  # Update nix packages
  
  # System monitoring and process utilities
  psutils   # Process utilities
  sysstat   # System performance tools
  
  # File and text utilities
  eza       # Modern ls replacement
  fd        # Fast find alternative
  tree      # Directory tree viewer
  micro     # Terminal text editor
  vim       # Text editor
  
  # Network utilities
  wget      # File downloader
  curl      # HTTP client
  
  # Text processing
  gawk      # GNU awk
  jq        # JSON processor
  fzf       # Fuzzy finder
  bc        # Calculator
  
  # System utilities
  git       # Version control
  pciutils  # PCI utilities (lspci)
  busybox   # Multi-call binary with many utilities
]

