{ pkgs, unstablePkgs, ... }:

let
  python = import ./python.nix { inherit pkgs; };
  sysutil = import ./sysutil.nix { inherit pkgs; };
  monitoring = import ./monitoring.nix { inherit pkgs; };
  gpu = import ./gpu.nix { inherit pkgs; };
  disk = import ./disk.nix { inherit pkgs; };
  wayland = import ./wayland.nix { inherit pkgs; };
  waylandUnstable = import ./wayland-unstable.nix { inherit unstablePkgs; };
  media = import ./media.nix { inherit pkgs; };
  electronics = import ./electronics.nix { inherit pkgs; };
  gaming = import ./gaming.nix { inherit pkgs; };
  dotnet = import ./dotnet.nix { inherit pkgs; };
  remoting = import ./remoting.nix { inherit pkgs; };
  phone = import ./phone.nix { inherit pkgs; };
  ai = import ./ai.nix { inherit pkgs; };
  unstable = import ./unstable.nix { inherit unstablePkgs; };
in
python
++ sysutil
++ monitoring
++ gpu
++ disk
++ wayland
++ waylandUnstable
++ media
++ electronics
++ gaming
++ dotnet
++ remoting
++ phone
++ ai
++ unstable

