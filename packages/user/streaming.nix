{ pkgs, ... }:

with pkgs; [
  # Game streaming
  sunshine      # Game streaming host (Sunshine server)
  moonlight-qt  # Game streaming client (Moonlight client)
]

