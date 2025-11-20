{ pkgs, unstablePkgs, ... }:

with pkgs; [
  # Game streaming
  # Note: sunshine is provided via unstable packages (packages/system/unstable.nix)
  # for a newer version. The stable version is also available but unstable is preferred.
  moonlight-qt  # Game streaming client (Moonlight client)
]

