#!/bin/bash
# Install nynex (animated pixel-art / ASCII landscapes) on Omarchy as a screensaver and
# live wallpaper.
#
#   ./install.sh            download the latest release build
#   ./install.sh --build    build from source instead (needs ~10 min on a Pixelbook Go)
#   ./install.sh --wallpaper  also start the live wallpaper now and at every login
#
# Re-run it to update. ./uninstall.sh puts everything back.
set -euo pipefail

REPO=kingof9x/nynex-screensaver
HERE=$(cd "$(dirname "$0")" && pwd)
BUILD=0
WALLPAPER=0
for arg in "$@"; do
  case $arg in
    --build) BUILD=1 ;;
    --wallpaper) WALLPAPER=1 ;;
    -h | --help) sed -n 2,10p "$0"; exit 0 ;;
    *) echo "Unknown option: $arg" >&2; exit 2 ;;
  esac
done

if [[ $(uname -m) != x86_64 ]]; then
  echo "Release builds are x86_64 only; building from source." >&2
  BUILD=1
fi

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

if ((BUILD == 0)); then
  echo "Downloading the latest nynex release..."
  if ! curl -fL --progress-bar -o "$TMP/nynex" "https://github.com/$REPO/releases/latest/download/nynex-linux-x86_64"; then
    echo "No Linux build in the latest release yet; building from source." >&2
    BUILD=1
  fi
fi

if ((BUILD == 1)); then
  sudo pacman -S --needed --noconfirm rust git
  git clone --depth 1 "https://github.com/$REPO" "$TMP/src"
  (cd "$TMP/src" && cargo build --release --locked)
  cp "$TMP/src/target/release/nynex" "$TMP/nynex"
fi

# The screensaver hook needs these (Omarchy has them already).
sudo pacman -S --needed --noconfirm jq socat >/dev/null

echo "Installing to /usr/local/bin (asks for your password)..."
sudo install -Dm755 "$TMP/nynex" /usr/local/bin/nynex
sudo install -Dm755 "$HERE/omarchy-launch-screensaver" /usr/local/bin/omarchy-launch-screensaver

# App launcher entry (Super + Space finds "nynex")
install -Dm644 "$HERE/nynex.desktop" "$HOME/.local/share/applications/nynex.desktop"
update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true

# nynex is the screensaver unless it was switched off in the app before
mkdir -p "$HOME/.config/nynex-screensaver"

if ((WALLPAPER == 1)); then
  AUTOSTART="$HOME/.config/hypr/autostart.lua"
  LINE='o.launch_on_start("/usr/local/bin/nynex --wallpaper") -- nynex wallpaper'
  if [[ -f $AUTOSTART ]]; then
    grep -q 'nynex wallpaper' "$AUTOSTART" || echo "$LINE" >>"$AUTOSTART"
  else
    echo 'exec-once = uwsm-app -- /usr/local/bin/nynex --wallpaper # nynex wallpaper' >>"$HOME/.config/hypr/autostart.conf"
  fi
  touch "$HOME/.config/nynex-screensaver/wallpaper.stop"
  sleep 1
  rm -f "$HOME/.config/nynex-screensaver/wallpaper.stop"
  setsid -f uwsm-app -- /usr/local/bin/nynex --wallpaper >/dev/null 2>&1 || setsid -f /usr/local/bin/nynex --wallpaper >/dev/null 2>&1
fi

cat <<MSG

nynex installed.

  * Open "nynex" from the app launcher to add landscapes and tune the look.
    Nothing shows until you add at least one image.
  * It is now Omarchy's screensaver. Try it: omarchy-launch-screensaver force
    (or Omarchy menu > System > Screensaver). The app's "My screensaver" box
    switches back to Omarchy's text one.
  * Live wallpaper: Start/Stop in the app, or: nynex --wallpaper
MSG
