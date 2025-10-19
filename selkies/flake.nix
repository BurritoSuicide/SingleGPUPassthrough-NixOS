{
  description = "Selkies GStreamer streaming module for NixOS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        selkies-gstreamer = pkgs.stdenv.mkDerivation {
          pname = "selkies-gstreamer";
          version = "unstable";

          src = pkgs.fetchFromGitHub {
            owner = "selkies-project";
            repo = "selkies-gstreamer";
            rev = "main";
            # You can run `nix-prefetch-url --unpack https://github.com/selkies-project/selkies-gstreamer/archive/refs/heads/main.tar.gz`
            # to get the correct sha256.
            sha256 = "sha256-1izww7syxfb6l50wjf95ippp70crp8dhmqz269yqch0ds74zlx64=";
          };

          nativeBuildInputs = [
            pkgs.pkg-config
            pkgs.cmake
            pkgs.makeWrapper
          ];

          buildInputs = with pkgs; [
            gstreamer
            gst-plugins-good
            gst-plugins-bad
            gst-plugins-ugly
            gst-libav
            webrtc-audio-processing
          ];

          # Selkies-gstreamer is not a traditional build; we just package the scripts.
          buildPhase = ''
            mkdir -p $out/bin
            cp -r $src/* $out/
          '';

          installPhase = ''
            mkdir -p $out/bin
            cp -r $src/* $out/
          '';
        };
      in {
        packages.default = selkies-gstreamer;
        nixosModules.selkies = import ./module.nix;
      });
}
