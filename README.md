# ZMK Config — TOTEM (No-Dongle)

Personal ZMK firmware for the [TOTEM](https://github.com/GEIGEIGEIST/TOTEM) — a 38-key column-staggered wireless split keyboard using two [Seeed XIAO nRF52840](https://wiki.seeedstudio.com/XIAO-nRF52840/) microcontrollers.

**This repo is for the no-dongle setup**: the left half connects directly to your computer via USB and acts as the BLE central. Use this when you want a simple two-piece wireless keyboard with ZMK Studio support.

> **Using a dongle?** See [zmk-dongle-screen](https://github.com/Tyler-Reagan/zmk-dongle-screen) — a separate repo for the three-piece dongle setup (left + right as BLE peripherals, XIAO dongle as USB central with status display).

---

## Repo structure

```
config/
  totem.keymap          ← keymap (edit this)
  totem_left.conf       ← left half config (bootloader support)
  totem_right.conf      ← right half config (bootloader support)
  west.yml              ← ZMK west manifest

boards/shields/totem/   ← TOTEM keyboard shield definition
  totem.dtsi            ← base matrix / kscan
  totem-layouts.dtsi    ← physical key positions (ZMK Studio)
  totem_left.overlay    ← left column GPIO assignments
  totem_right.overlay   ← right column GPIO assignments
  Kconfig.shield        ← shield Kconfig symbols
  Kconfig.defconfig     ← ZMK split role defaults
  totem.zmk.yml         ← ZMK Studio shield metadata

build.yaml              ← GitHub Actions build matrix
Makefile                ← workflow helper (requires gh CLI)
.github/workflows/
  build.yml             ← GitHub Actions build workflow
```

---

## Artifacts

| Artifact | Shield | Role |
|---|---|---|
| `totem_left` | `totem_left` | Left half — USB central, ZMK Studio enabled |
| `totem_right` | `totem_right` | Right half — BLE peripheral |
| `settings_reset` | `settings_reset` | Clears all BLE bond data |

---

## Makefile workflow

Requires the [GitHub CLI](https://cli.github.com/) (`gh`). ZMK firmware is built in GitHub Actions — the Makefile wraps `gh` commands for convenience.

```
make help          Show all targets and workflow summary
make build         Trigger a GitHub Actions build
make status        List recent build runs (latest 5)
make download      Download firmware artifacts → firmware/
make flash-left    Copy left UF2 to mounted XIAO bootloader drive
make flash-right   Copy right UF2 to mounted XIAO bootloader drive
```

### Typical workflow

```sh
# 1. Edit your keymap
vim config/totem.keymap

# 2. Trigger a build
make build

# 3. Check when it finishes
make status

# 4. Download artifacts once the build succeeds
make download
# → firmware/totem_left/zmk.uf2
# → firmware/totem_right/zmk.uf2

# 5. Flash each half (double-tap reset first to enter bootloader)
make flash-left
make flash-right
```

> The `BOOT_LEFT` and `BOOT_RIGHT` variables default to `/Volumes/XIAO-SENSE`. Override if your drive mounts under a different name:
> ```sh
> make flash-left BOOT_LEFT=/Volumes/XIAO
> ```

---

## Flashing

### Enter bootloader mode

**Double-tap the reset button** on the XIAO — the drive mounts as `XIAO-SENSE` (or `XIAO`) automatically. Or hold the boot button while plugging in USB.

Flash one half at a time with the other disconnected (or powered off).

### First-time setup

1. Flash `settings_reset` to both halves to clear any stale bond data.
2. Flash `totem_left` to the left half.
3. Flash `totem_right` to the right half.
4. Power on both halves. The right half (peripheral) advertises to the left; they pair automatically.
5. The left half then advertises to your computer. Open Bluetooth settings and pair **TOTEM**.

### Subsequent updates

Just reflash both halves with updated firmware — bond data is preserved in EEPROM.

---

## ZMK Studio

[ZMK Studio](https://zmk.studio/) lets you remap keys live over USB without reflashing.

- Connect the **left half** to your computer via USB.
- Open [zmk.studio](https://zmk.studio/) in a Chromium-based browser.
- **TOTEM** appears automatically.
- Changes are written to the keyboard's flash instantly.

Studio locking is disabled — no unlock sequence required. Studio changes persist across power cycles but are overwritten on the next firmware flash.

> ZMK Studio connects to the **left half only**. The right half doesn't expose the Studio interface.

---

## Keymap

Six layers. Source: [`config/totem.keymap`](config/totem.keymap).

| # | Layer | Hand | Activation |
|---|---|---|---|
| 0 | **BASE** | Both | Default |
| 1 | **DEV** | Right | Hold `DEV/SPC` (right thumb inner) |
| 2 | **SYS** | Right | Hold `SYS/TAB` (right thumb middle) |
| 3 | **NUM** | Left | Hold `NUM/ENT` (left thumb middle) |
| 4 | **FUN** | Left | Hold `FUN/DEL` (left thumb inner) |
| 5 | **BOOT** | Both | Assign via ZMK Studio or combo |

**BASE** — QWERTY with home-row mods (`GUI/S` `CTRL/D` `SHIFT/F` left; `SHIFT/J` `CTRL/K` `GUI/L` right). Left outer pinky: `HYPER` (Ctrl+Shift+Alt+GUI). Right outer pinky: `'`. All three thumbs per side are layer-tap.

**DEV** — Developer symbols on the right hand: `-{}` `` ` `` `=` `_[]'$&|*`. Left hand: modifiers. Right thumbs: `@()`. Right outer pinky: `Shift+Tab`.

**SYS** — Navigation and media on the right: arrows, volume, prev/next/play/mute, screenshots, refresh, undo/cut/copy/paste. Left outer pinky: clear all BT bonds. Right outer pinky: lock screen.

**NUM** — Numpad on the left: `-789` / `=456` / `123`, `.0` on thumbs. Right hand: modifiers.

**FUN** — Function keys on the left: `F12 F7–F9` / `F11 F4–F6` / `F10 F1–F3`. `SPC`/`TAB` on thumbs. Right hand: modifiers.

**BOOT** — `&sys_reset` (soft reset) on top-row outer keys, `&bootloader` on bottom-row outer keys. Activate via ZMK Studio or a keymap combo.

---

## BLE profiles

ZMK supports up to 5 Bluetooth profiles for pairing with multiple hosts.

| Binding | Action |
|---|---|
| `&bt BT_SEL 0/1/2` | Switch to profile 0, 1, or 2 |
| `&bt BT_CLR` | Clear bond on active profile |
| `&bt BT_CLR_ALL` | Clear all bonds (on SYS layer, left outer pinky) |

After switching to an unpaired profile, the left half begins advertising. Pair **TOTEM** on the new host via Bluetooth settings.

---

## FAQ

**Double-tap reset isn't working.**
The firmware must be flashed at least once for double-tap detection to work (it's implemented in ZMK, not the bootloader). On a fresh XIAO with no firmware, hold the boot button while plugging in USB to enter bootloader manually for the first flash.

**The halves aren't communicating after reflashing.**
The right half may have a stale BLE bond. Flash `settings_reset` to both halves, then reflash normal firmware and re-pair.

**ZMK Studio shows "Keyboard Locked".**
This shouldn't happen — Studio locking is disabled in this config (`CONFIG_ZMK_STUDIO_LOCKING=n`). If it does, reflash `totem_left`.

**How do I switch between this setup and the dongle setup?**
They're completely separate repos that produce different firmware. Flash from whichever repo matches your current hardware setup. The bond data is per-device — you may want to run `settings_reset` when switching modes.

**GitHub Actions is failing.**
Check the Actions tab in the repo. Common causes: a keymap syntax error in `totem.keymap`, or a ZMK API change on `main`. Check the [ZMK changelog](https://zmk.dev/docs/changelog) for breaking changes.

**Where do I find the built firmware if I don't use `make download`?**
Go to the **Actions** tab in your GitHub repo → select the latest successful run → scroll to **Artifacts** at the bottom of the run summary.

**Do I need to redo first-time setup after every reflash?**
No. Bond data is stored in EEPROM and survives firmware updates. Only reflash `settings_reset` if the halves stop pairing with each other or if you're switching from the dongle setup.
