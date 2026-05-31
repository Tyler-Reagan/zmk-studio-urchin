# ZMK Config — Urchin (No-Dongle)

Personal ZMK firmware for the [Urchin](https://github.com/duckyb/urchin) — a 34-key column-staggered wireless split keyboard using two [nice!nano v2](https://nicekeyboards.com/nice-nano/) microcontrollers (nRF52840) with [nice!view](https://nicekeyboards.com/nice-view/) Sharp Memory displays.

**This repo is for the no-dongle setup**: the left half connects directly to your computer via USB and acts as the BLE central.

---

## Repo structure

```
.github/workflows/
  build.yml             ← GitHub Actions build workflow
config/
  urchin_left.conf      ← left half config (BT, sleep, display)
  urchin_right.conf     ← right half config (BT, sleep, display)
  urchin.keymap         ← keymap (edit this)
  west.yml              ← ZMK west manifest

zephyr/
  module.yml            ← declares repo root as Zephyr board_root

build.yaml              ← GitHub Actions build matrix
Makefile                ← workflow helper (requires gh CLI)
```

---

## Displays

Five display options across four branches. ZMK Studio is only available on `main` — the `display/*` branches use ZMK v0.3 which is incompatible with Studio.

| Display | Branch | ZMK | ZMK Studio |
|---------|--------|-----|------------|
| [nice-view-gem](https://github.com/M165437/nice-view-gem) — animated crystal (default) | `main` | main / Zephyr 4.1 | Yes |
| [nice-view-elemental](https://github.com/kevinpastor/nice-view-elemental) — minimal geometric | `main` | main / Zephyr 4.1 | Yes |
| [Hammerbeam Slideshow](https://github.com/GPeye/hammerbeam-slideshow) | `display/hammerbeam` | v0.3 | No |
| [Corro Animation](https://github.com/GPeye/mario-peripheral-animation) | `display/corro` | v0.3 | No |
| [Press Start](https://github.com/Ziembski/nice-view-press-start) | `display/press-start` | v0.3 | No |

### Switching displays on `main`

`nice_view_gem` is active by default. To switch to `nice_view_elemental`, change one word in `build.yaml`:

```yaml
# default
shield: urchin_left nice_view_adapter nice_view_gem

# swap to elemental
shield: urchin_left nice_view_adapter nice_view_elemental
```

Both modules are loaded in `config/west.yml` — no manifest changes needed.

### Switching to a `display/*` branch

```sh
git checkout display/hammerbeam   # or display/corro, display/press-start
```

> [!IMPORTANT]
> The `display/*` branches use ZMK v0.3 and do not support ZMK Studio. Switch back to `main` to regain Studio.

---

## Artifacts

| Artifact | Role |
|----------|------|
| `urchin_left` | Left half — USB central, ZMK Studio enabled (on `main`) |
| `urchin_right` | Right half — BLE peripheral |
| `settings_reset` | Clears all BLE bond data |

---

## Makefile workflow

Requires the [GitHub CLI](https://cli.github.com/) (`gh`). ZMK firmware is built in GitHub Actions — the Makefile wraps `gh` commands for convenience.

```
make help          Show all targets and workflow summary
make build         Trigger a GitHub Actions build
make status        List recent build runs (latest 5)
make download      Download firmware artifacts → ~/Desktop/urchin_firmware/{timestamp}/
make flash-left    Copy left UF2 to mounted nice!nano bootloader drive
make flash-right   Copy right UF2 to mounted nice!nano bootloader drive
```

### Typical workflow

```sh
# 1. Edit your keymap
vim config/urchin.keymap

# 2. Trigger a build
make build

# 3. Check when it finishes
make status

# 4. Download artifacts once the build succeeds
make download
# → ~/Desktop/urchin_firmware/{YYYYMMDD-hhmmss}/urchin_left.uf2
# → ~/Desktop/urchin_firmware/{YYYYMMDD-hhmmss}/urchin_right.uf2
# → ~/Desktop/urchin_firmware/{YYYYMMDD-hhmmss}/settings_reset.uf2

# 5. Flash each half (double-tap reset first to enter bootloader)
make flash-left
make flash-right
```

> [!TIP]
> The `BOOT_LEFT` and `BOOT_RIGHT` variables default to `/Volumes/NICENANO`. Override if your drive mounts under a different name:
> ```sh
> make flash-left BOOT_LEFT=/Volumes/{DRIVE_NAME}
> ```

---

## Flashing

### Enter bootloader mode

**Double-tap the reset button** on the nice!nano — the drive mounts as `NICENANO` automatically.

Flash one half at a time with the other disconnected (or powered off).

### First-time setup

1. Flash `settings_reset` to both halves to clear any stale bond data.
2. Flash `urchin_left` to the left half.
3. Flash `urchin_right` to the right half.
4. Power on both halves. The right half (peripheral) advertises to the left and they pair automatically.
5. The left half advertises to your computer. Open Bluetooth settings and pair **Urchin**.

### Subsequent updates

Reflash both halves with updated firmware — bond data is preserved in EEPROM.

---

## ZMK Studio

[ZMK Studio](https://zmk.studio/) lets you remap keys live over USB without reflashing.

- Connect the **left half** to your computer via USB.
- Open [zmk.studio](https://zmk.studio/) in a Chromium-based browser.
- **Urchin** appears automatically.
- Changes write to the keyboard's flash instantly.

Studio locking is disabled — no unlock sequence required. Studio changes persist across power cycles but are overwritten on the next firmware flash.

> [!NOTE]
> ZMK Studio is only available on the `main` branch. The `display/*` branches use ZMK v0.3 which predates Studio.

---

## Keymap

Six layers. Source: [`config/urchin.keymap`](config/urchin.keymap).

| # | Layer | Activation |
|---|-------|------------|
| 0 | **BASE** | Default |
| 1 | **DEV** | Hold left outer thumb (`DEV+SPC`) |
| 2 | **SYS** | Hold left inner thumb (`SYS+TAB`) |
| 3 | **NUM** | Hold right outer thumb (`NUM+ENT`) |
| 4 | **FUN** | Combo: both right thumbs (`BSPC` + `NUM+ENT`) |
| 5 | **BOOT** | Assign via ZMK Studio |

**BASE** — QWERTY with home-row mods (`GUI/S` `CTRL/D` `SHIFT/F` left; `SHIFT/J` `CTRL/K` `GUI/L` right). Left thumbs: `SYS+TAB` (inner), `DEV+SPC` (outer). Right thumbs: `BSPC` (inner), `NUM+ENT` (outer).

**Combos** — Both left thumbs → `ESC`. Both right thumbs → momentary `FUN` layer.

**DEV** — Developer symbols on the right: `-{}` `` ` `` `=_[]'$&|*`. Left: one-shot modifiers. Right thumbs: `()`.

**SYS** — Navigation and media on the right: arrows, volume, prev/next/play, screenshots, reload, undo/cut/copy/paste/lock. Left: BT profile select and clear.

**NUM** — Numpad on the left: `-789` / `=456` / `123`, `.0` on thumbs. Right: modifiers.

**FUN** — Function keys on the left: `F12 F7–F9` / `F11 F4–F6` / `F10 F1–F3`. `SPC`/`TAB` on thumbs. Right: modifiers.

**BOOT** — `&sys_reset` on top-row outer keys, `&bootloader` on bottom-row outer keys.

---

## BLE profiles

ZMK supports up to 5 Bluetooth profiles for pairing with multiple hosts.

| Binding | Action |
|---------|--------|
| `&bt BT_SEL 0/1/2` | Switch to profile 0, 1, or 2 |
| `&bt BT_CLR` | Clear bond on active profile |
| `&bt BT_CLR_ALL` | Clear all bonds (SYS layer, left outer pinky) |

After switching to an unpaired profile, the left half begins advertising. Pair **Urchin** on the new host via Bluetooth settings.

---

## FAQ

**Double-tap reset isn't working.**
The nice!nano v2 ships with a UF2 bootloader — double-tap reset works on a fresh board before any firmware is flashed.

**The halves aren't communicating after reflashing.**
The right half may have a stale BLE bond. Flash `settings_reset` to both halves, then reflash normal firmware and re-pair.

**ZMK Studio shows "Keyboard Locked".**
This shouldn't happen — Studio locking is disabled (`CONFIG_ZMK_STUDIO_LOCKING=n`). If it does, reflash `urchin_left`.

**GitHub Actions is failing.**
Check the Actions tab. Common causes: a keymap syntax error in `urchin.keymap`, or a ZMK API change on `main`. Check the [ZMK changelog](https://zmk.dev/docs/changelog) for breaking changes.

**Where do I find built firmware without `make download`?**
Go to the **Actions** tab → select the latest successful run → scroll to **Artifacts** at the bottom.

**Do I need to redo first-time setup after every reflash?**
No. Bond data survives firmware updates. Only reflash `settings_reset` if the halves stop pairing with each other.
