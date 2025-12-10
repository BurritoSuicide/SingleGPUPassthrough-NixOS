{ pkgs, unstablePkgs, ... }:

let
  imageLibs = import ./image-libs.nix { inherit pkgs; };
  kde = import ./kde.nix { inherit pkgs; };
  streaming = import ./streaming.nix { inherit pkgs unstablePkgs; };
  communication = import ./communication.nix { inherit pkgs; };
  mediaTools = import ./media-tools.nix { inherit pkgs; };
  gaming = import ./gaming.nix { inherit pkgs; };
  musicStreaming = import ./music-streaming.nix { inherit pkgs; };
  musicProduction = import ./music-production.nix { inherit pkgs; };
  astro = import ./astro.nix { inherit pkgs; };
  dev = import ./dev.nix { inherit pkgs; };
  productivity = import ./productivity.nix { inherit pkgs; };
  threeD = import ./3d.nix { inherit pkgs; };
  theming = import ./theming.nix { inherit pkgs; };
  imageEditing = import ./image-editing.nix { inherit pkgs unstablePkgs; };
in
imageLibs
++ kde
++ streaming
++ communication
++ mediaTools
++ gaming
++ musicStreaming
++ musicProduction
++ astro
++ dev
++ imageEditing
++ productivity
++ threeD
++ theming

