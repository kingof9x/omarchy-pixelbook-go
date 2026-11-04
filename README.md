# Omarchy on the Google Pixelbook Go

Notes and fixes for running [Omarchy](https://omarchy.org) on a Google Pixelbook Go (board name **Atlas**).

Out of the box, Omarchy (and most other distros) boots to a glitched screen on this laptop: flickering horizontal lines and garbage on the left side of the display. This repo documents what it took to get a clean, working install.

> **TL;DR:** Boot the installer with `nomodeset`, then on the installed system add `i915.enable_psr=0 i915.enable_dc=0` to the kernel command line and boot the **LTS kernel**. Do **not** add `i915.enable_fbc=0`, because it makes the problem worse.

---

## Functionality checklist

✅ working  ⚠️ working with a workaround  ❌ not working  ⬜ not tested yet

| Feature | Status | Notes |
|---|---|---|
| Boot Omarchy installer ISO | ⚠️ | Needs a `nomodeset` boot entry (see [Installer](#1-booting-the-installer)) |
| Install to internal drive | ✅ | Default Omarchy install, with full-disk encryption |
| Disk unlock (LUKS) at boot | ✅ | |
| Internal display, LTS kernel | ⚠️ | Needs `i915.enable_psr=0 i915.enable_dc=0` |
| Internal display, `linux-omarchy` 7.2.15 | ❌ | Glitches even with the fix (7.2.8 worked) |
| Boot splash / password screen | ⬜ | Glitches; fix applied, still to be verified (see [Splash screen](#5-fixing-the-glitched-boot-splash)) |
| Hyprland desktop | ✅ | On the LTS kernel |
| Keyboard | ✅ | |
| Touchpad | ⬜ | |
| Touchscreen | ⬜ | |
| Wi-Fi | ⬜ | |
| Bluetooth | ⬜ | |
| Audio (speakers / headphones / mic) | ⬜ | Chromebooks usually need an extra audio setup script |
| Webcam | ❌ | Needs a patched libcamera (see [Camera](#camera)) |
| Screen brightness keys | ⬜ | |
| Keyboard backlight | ⬜ | |
| Suspend / resume | ⬜ | |
| Hibernate | ⬜ | Omarchy sets this up (`resume=` is on the kernel command line) |
| External display (USB-C) | ⬜ | |
| Battery reporting / charging | ⬜ | |

---

## Hardware

- **Laptop:** Google Pixelbook Go (Atlas)
- **CPU / GPU:** Intel Amber Lake (Kaby Lake family), integrated graphics, driver `i915`
  - The kernel identifies it as `kabylake/ulx (device ID 591c)`
- **Camera:** Sony IMX208 sensor on the Intel IPU3
- **Firmware:** TODO: add the MrChromebox firmware type and version (`sudo dmidecode -s bios-version`)

## What was tried first

- **Omarchy, default boot:** glitched display.
- **Other distros:** glitched display.
- **Fedora 44 / 45:** glitched by default, but **boots cleanly with "basic / safe graphics mode"**. That option only adds the `nomodeset` kernel parameter, which was the first clue that the Intel graphics driver was the problem.

---

## The fix, step by step

### 1. Booting the installer

The Omarchy ISO boots with **GRUB**, and its menu is hidden (`timeout=0`, `timeout_style=hidden`), so pressing **E** to edit the boot options does nothing. You can't edit the menu on a normally flashed USB stick either, because the ISO's files are read-only. Rufus in ISO mode didn't help, because `airootfs.sfs` is over 4 GB and won't fit on a FAT32 stick.

**Solution:** use [Ventoy](https://www.ventoy.net) and its **Boot Conf Replace** plugin to swap in an edited copy of the ISO's GRUB menu.

The ready-made files are in the [`ventoy/`](ventoy/) folder of this repo. Copy that folder to the root of your Ventoy USB stick. They're built for **Omarchy 4.0.6** (ISO build `2026-10-19-22-18-53-00`). For a different ISO version, update the filename in `ventoy.json` and the `archisosearchuuid=` value in `omarchy.cfg`, or redo the edits below on that ISO's own `grub.cfg`.

The USB stick layout:

```
F:\
├── omarchy-4.0.6.iso
└── ventoy\
    ├── omarchy.cfg      ← edited copy of the ISO's /boot/grub/grub.cfg
    └── ventoy.json
```

`ventoy/ventoy.json`:

```json
{
  "conf_replace": [
    {
      "iso": "/omarchy-4.0.6.iso",
      "org": "/boot/grub/grub.cfg",
      "new": "/ventoy/omarchy.cfg"
    }
  ]
}
```

Changes made in `omarchy.cfg` (start from a copy of the ISO's `/boot/grub/grub.cfg`):

1. Make the menu visible:
   ```
   timeout=15
   timeout_style=menu
   ```
2. Add two entries below the main Omarchy entry. They're copies of it, with one parameter added to the end of the `linux` line:
   ```
   menuentry "Omarchy - no PSR (try first)" ... {
       set gfxpayload=keep
       linux /arch/boot/x86_64/vmlinuz-linux-t2 archisobasedir=arch archisosearchuuid=<from original> quiet splash xe.enable_panel_replay=0 initramfs_async=0 i915.enable_psr=0
       initrd /arch/boot/x86_64/initramfs-linux-t2.img
   }

   menuentry "Omarchy - safe graphics (nomodeset)" ... {
       set gfxpayload=keep
       linux /arch/boot/x86_64/vmlinuz-linux-t2 archisobasedir=arch archisosearchuuid=<from original> quiet splash xe.enable_panel_replay=0 initramfs_async=0 nomodeset
       initrd /arch/boot/x86_64/initramfs-linux-t2.img
   }
   ```
   Copy the `archisosearchuuid=` value from the original entry. It's different for each ISO build.

Boot the stick in Ventoy **normal mode**, pick the ISO, and choose **Omarchy - safe graphics (nomodeset)**.

`nomodeset` is fine for installing because the Omarchy installer runs in a text console. It is **not** a fix for the installed desktop, because Hyprland needs the real graphics driver.

### 2. First boot of the installed system

The installed system uses the **Limine** bootloader, not GRUB. Its menu is visible, and pressing **E** does work.

1. At the Limine menu, highlight Omarchy and press **E**.
2. Go to the end of the `cmdline:` line and add:
   ```
    i915.enable_psr=0 i915.enable_dc=0
   ```
3. Press **F10** to boot. On the Pixelbook Go this is the 10th key in the top row.

### 3. Make the kernel parameters permanent

Omarchy generates `/boot/limine.conf` from `/etc/default/limine`, so edit `/etc/default/limine`, not `limine.conf`. Changes made directly to `limine.conf` are overwritten on the next kernel update.

```bash
echo 'KERNEL_CMDLINE[default]+=" i915.enable_psr=0 i915.enable_dc=0"' | sudo tee -a /etc/default/limine
sudo limine-update
sudo grep -n cmdline /boot/limine.conf   # verify
```

Only append with `+=` when the file already contains a `KERNEL_CMDLINE[default]` line, which Omarchy's does. Replacing that line drops the root/encryption parameters, and the system won't boot.

### 4. Use the LTS kernel

After a system update moved `linux-omarchy` from **7.2.8 → 7.2.15**, the display glitched again, even with the parameters above. The old kernel package wasn't in the pacman cache, because it was installed from the ISO's offline repo. The LTS kernel works:

```bash
sudo pacman -S linux-lts
sudo grep -n -B2 -A2 lts /boot/limine.conf   # LTS entry should have the i915 params
```

Make LTS the default boot entry:

```bash
grep -h BOOT_ORDER /etc/limine-entry-tool.conf /etc/default/limine
echo 'BOOT_ORDER="*lts, *, *fallback, Snapshots"' | sudo tee -a /etc/default/limine
sudo limine-update
```

`linux-omarchy` stays installed and keeps updating. Test newer versions from the boot menu, and fall back to LTS if they glitch.

### 5. Fixing the glitched boot splash

The Plymouth splash and password screen still glitch, because the `i915` driver loads in the initramfs (the `kms` hook) and takes over the display early. Removing `kms` makes the splash run on the simple firmware framebuffer, and `i915` then loads after the disk is unlocked.

Use a drop-in file instead of editing Omarchy's `omarchy_hooks.conf`, so Omarchy updates don't undo it:

```bash
echo '_h=(); for h in "${HOOKS[@]}"; do [[ $h != kms ]] && _h+=("$h"); done; HOOKS=("${_h[@]}"); unset _h' | sudo tee /etc/mkinitcpio.conf.d/zz-no-kms.conf
sudo limine-mkinitcpio
```

To undo:

```bash
sudo rm /etc/mkinitcpio.conf.d/zz-no-kms.conf
sudo limine-mkinitcpio
```

---

## Lessons learned / gotchas

- **`i915.enable_fbc=0` makes things worse on this machine.** With framebuffer compression off, the display hardware has to read more data and can't keep up. The log shows `CPU pipe A FIFO underrun` and the screen gets lines across it. Leave FBC on.
- **`i915.fastboot` no longer exists** in current kernels. The log shows `unknown parameter 'fastboot' ignored`.
- **Check your typos.** The first "working" boot actually had `i915.enable_fbc==` and `intel_iomu=igfx_off`. Both were silently ignored, and that's how we found out which parameters really mattered. Check what actually applied with:
  ```bash
  journalctl -b -k | grep -iE 'command line|i915|underrun'
  ```
- **The kernel version matters.** `linux-omarchy` 7.2.8 worked with `enable_psr=0 enable_dc=0`, 7.2.15 did not, and `linux-lts` does.
- **The glitch is a layer on top of a working image.** The desktop is drawn correctly underneath. You can see the colors change from the splash to the wallpaper through the glitch.

## Rescue: getting into a broken install

If the display glitches and you can't do anything:

1. At the Limine menu, press **E** and add ` nomodeset` to the end of `cmdline:`, then press **F10**.
2. Hyprland may start on the fallback display (slow, but usable). If it doesn't, press **Ctrl + Alt + F2** and log in at the text console.
3. Fix the configuration, then reboot without `nomodeset`.

---

## Camera

The camera is a Sony IMX208 on the Intel IPU3. Both have kernel drivers, but libcamera needs a sensor helper for the IMX208 that isn't in an official release yet:

- Forum thread: [Atlas (Pixelbook Go) camera support on Linux](https://forum.chrultrabook.com/t/atlas-pixelbook-go-camera-support-on-linux/4155)
- Patch: [libcamera IMX208 sensor helper](https://patchwork.libcamera.org/patch/23141/), which still needs changes before it can be merged

Status: not working yet. See the checklist above.

---

## References

- [Omarchy](https://omarchy.org)
- [Ventoy Boot Conf Replace plugin](https://www.ventoy.net/en/plugin_bootconf_replace.html)
- [Chromebook to Ultrabook forum](https://forum.chrultrabook.com)
- [Fedora basic graphics mode test case](https://fedoraproject.org/wiki/QA:Testcase_Anaconda_User_Interface_Basic_Video_Driver), which shows that the safe option is just `nomodeset`
