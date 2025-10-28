#!/usr/bin/env bash
# Update NixOS system and flakes
set -e

echo "🔄 Updating flake inputs..."
cd /etc/nixos
sudo nix flake update

echo "🔨 Rebuilding NixOS configuration..."
sudo nixos-rebuild switch --flake /etc/nixos#

echo "✅ System updated successfully!"
