#!/usr/bin/env bash
# Push /etc/nixos to GitHub
set -e

cd /etc/nixos

echo "📝 Staging changes..."
sudo git add .

echo "💬 Creating commit..."
if [ -z "$1" ]; then
  # Default commit message with timestamp
  sudo git commit -m "Update config $(date '+%Y-%m-%d %H:%M:%S')"
else
  # Custom commit message
  sudo git commit -m "$1"
fi

echo "🚀 Pushing to GitHub..."
# Use regular user's SSH keys and environment, not root's
sudo -u "$SUDO_USER" -H bash -c "cd /etc/nixos && git push origin main"

echo "✅ Changes pushed successfully!"
