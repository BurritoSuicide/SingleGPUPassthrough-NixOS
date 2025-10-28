#!/usr/bin/env bash
# NixOS garbage collection
set -e

echo "🗑️  Running aggressive garbage collection..."

# Keep only the last 3 generations
echo "Keeping only the last 3 generations..."
sudo nix-env --delete-generations +3
sudo nix-collect-garbage -d

# Optimize the Nix store
echo "Optimizing Nix store..."
sudo nix-store --optimize

echo "📊 Current disk usage:"
df -h /nix/store

echo "✅ Garbage collection complete!"
