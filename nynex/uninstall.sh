#!/bin/bash
# Remove nynex and give Omarchy its own screensaver back. Your nynex settings and images in
# ~/.config/nynex-screensaver are kept; delete that folder to remove them too.
set -euo pipefail

touch "$HOME/.config/nynex-screensaver/wallpaper.stop" 2>/dev/null || true
pkill -f '/usr/local/bin/nynex --wallpaper' 2>/dev/null || true

if grep -q nynex /usr/local/bin/omarchy-launch-screensaver 2>/dev/null; then
  sudo rm -f /usr/local/bin/omarchy-launch-screensaver
fi
sudo rm -f /usr/local/bin/nynex
rm -f "$HOME/.local/share/applications/nynex.desktop"

for f in "$HOME/.config/hypr/autostart.lua" "$HOME/.config/hypr/autostart.conf"; do
  [[ -f $f ]] && sed -i '/nynex wallpaper/d' "$f"
done

echo "nynex removed. Omarchy's own screensaver is back."
