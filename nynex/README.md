# nynex on Omarchy

[nynex](https://github.com/kingof9x/nynex-screensaver) turns landscape photos and GIFs into slowly
animated pixel-art / ASCII scenes. This folder installs it on Omarchy as:

- **the idle screensaver**, in place of Omarchy's text screensaver, and
- **a live wallpaper**, under your windows on every monitor.

It is the same app as the Windows version (v0.9.0 and later), with the same landscapes list, look
and motion sliders, per-image looks and transitions.

## Install

```bash
git clone https://github.com/kingof9x/omarchy-pixelbook-go
cd omarchy-pixelbook-go/nynex
./install.sh               # or ./install.sh --wallpaper to also start the live wallpaper at login
```

It downloads the latest Linux build from the nynex releases (or builds from source with
`--build`) and installs:

| File | What it does |
|---|---|
| `/usr/local/bin/nynex` | The app. Run it (or pick **nynex** in the app launcher) to add images and tune the look. |
| `/usr/local/bin/omarchy-launch-screensaver` | [Screensaver hook](omarchy-launch-screensaver), see below. |
| `~/.local/share/applications/nynex.desktop` | App launcher entry. |

Add at least one image in the app first; with no landscapes the screen just stays black.

## Screensaver

Omarchy 4's idle service (part of its Quickshell shell) runs `omarchy-launch-screensaver` after
`idle.screensaver` seconds (`~/.config/omarchy/shell.json`, 150 by default). `/usr/local/bin` comes
before `/usr/bin` on the PATH, so the hook runs instead of Omarchy's launcher. It does what
Omarchy's launcher does, one full-screen window per monitor on its own special workspace, but the
window is `nynex --screensaver --app-id org.omarchy.screensaver` instead of a terminal. Because the
app id matches, everything else keeps working: Omarchy's window rules, the lock after
`idle.lock` seconds, the menu's **Screensaver** entry and the screensaver on/off toggle.

In the nynex app:

- **My screensaver** switches between nynex and Omarchy's own text screensaver (the hook then
  hands over to `/usr/bin/omarchy-launch-screensaver`).
- **after N min** changes `idle.screensaver` in `shell.json`.

Try it any time with `omarchy-launch-screensaver force`. Move the mouse or press a key to close it.

## Live wallpaper

**Wallpaper → Start / Stop** in the app, or `nynex --wallpaper` from a terminal. Tick **Start at
login** (or install with `--wallpaper`) to add it to `~/.config/hypr/autostart.lua`.

It is a Wayland layer-shell surface (namespace `nynex-wallpaper`) on the *bottom* layer, so it
sits over Omarchy's background but under every window, and ignores the mouse. Theme changes
still swap Omarchy's background underneath; stop nynex to see it. Problems are logged to
`~/.config/nynex-screensaver/wallpaper.log`.

### On the Pixelbook Go

Rendering is done on the CPU. The wallpaper only draws when Hyprland asks for a frame and renders
at the screen's logical size (1920×1080 on the 4K model at 2× scale), but it still costs battery
while it is visible. Set **Frame rate** to 15–20 in the app if the fan or battery life suffer.

## Remove

```bash
./uninstall.sh
```

Removes the app, the hook, the launcher entry and the autostart line. Your images and settings in
`~/.config/nynex-screensaver` stay.
