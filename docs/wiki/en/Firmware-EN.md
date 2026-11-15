# Firmware Versions and Compilation

[← Home](Home-EN) · [中文](Firmware) · **English**

## Languages

All firmware configurations exist twice:

| Directory | Language | Entity names | Status |
|:----------|:---------|:-------------|:-------|
| `firmware/en/` | English | ASCII (`Fan 1`, `Temp A`, `Uptime` …) | **Primary / recommended** |
| `firmware/zh/` | Chinese | Original Chinese names | Chinese edition, functionally identical |

- **English is the primary build**: it is the default download, it is what this Wiki documents, and it keeps entity IDs short and readable.
- **The Chinese edition keeps the original entity names** so existing Chinese dashboards and automations keep working; its API paths need full percent-encoding (see [HTTP API](HTTP-API-EN)).
- The two editions differ only in entity names and comments — the hardware pins, the control algorithm, the defaults and the API key are identical.

## Version matrix

> **Since 2026-11-12 every controller sold is dual-core**, and the active firmware is v2.0 built for dual-core operation. The three variants below are the only active builds, and all of them are dual-core.

| Firmware | CPU | 4 fans | RPM | Temperature closed loop | Radar | BLE Proxy | Config file (English) |
|:-----|:------:|:--------:|:----:|:--------:|:----:|:---------:|:---------|
| v2.0 Basic | Dual-core | ✅ | ✅ | - | - | ✅ | `firmware/en/v2.0/dual-core/basic/config.yaml` |
| v2.0 DS18B20 | Dual-core | ✅ | ✅ | ✅ | - | ✅ | `firmware/en/v2.0/dual-core/ds18b20/config.yaml` |
| v2.0 DS18B20 + radar | Dual-core | ✅ | ✅ | ✅ | ✅ | ✅ | `firmware/en/v2.0/dual-core/ds18b20-radar/config.yaml` |

Every path above has a Chinese twin under `firmware/zh/` with exactly the same subdirectory, for example `firmware/zh/v2.0/dual-core/ds18b20-radar/config.yaml`.

The config skeleton shared by all versions:

| Config key | Value | Effect |
|:-------|:---|:-----|
| `esp32.board` | `esp32dev` | ESP32-WROOM-32 |
| `esp32.variant` | `ESP32` | — |
| `esp32.framework` | `esp-idf` | not Arduino |
| `CONFIG_FREERTOS_UNICORE` | omitted in the active dual-core builds (`"y"` only in the archived single-core builds) | active builds schedule FreeRTOS on both cores |
| `CONFIG_ESP_SYSTEM_PANIC_PRINT_REBOOT` | `y` | automatic reboot after a crash |
| `logger.level` | `INFO` | serial / web log level |
| `web_server.port` | `80` | web panel and REST API |
| `bluetooth_proxy.active` | `true` | actively connect to BLE devices |

## Archived builds

The **entire v1.0 line** is archived, together with the single-core v2.0 configurations used by controllers shipped **before 2026-11-12**:

| Firmware | CPU | Config file (English) | Config file (Chinese) |
|:-----|:------:|:---------|:---------|
| v1.0 dual-core | Dual-core | `firmware/en/archive/v1.0/dual-core/config.yaml` | `firmware/zh/archive/v1.0/dual-core/config.yaml` |
| v1.0 single-core | Single-core | `firmware/en/archive/v1.0/single-core/config.yaml` | `firmware/zh/archive/v1.0/single-core/config.yaml` |
| v2.0 Basic (single-core) | Single-core | `firmware/en/archive/v2.0/single-core/basic/config.yaml` | `firmware/zh/archive/v2.0/single-core/basic/config.yaml` |
| v2.0 DS18B20 (single-core) | Single-core | `firmware/en/archive/v2.0/single-core/ds18b20/config.yaml` | `firmware/zh/archive/v2.0/single-core/ds18b20/config.yaml` |
| v2.0 DS18B20 + radar (single-core) | Single-core | `firmware/en/archive/v2.0/single-core/ds18b20-radar/config.yaml` | `firmware/zh/archive/v2.0/single-core/ds18b20-radar/config.yaml` |

What "archived" means here:

- These configs are **no longer built by CI** and are **not part of any Release** — there is no `v1.0-*` and no single-core v2.0 download any more. You have to compile them locally (see [Custom compilation](#custom-compilation)) and flash the resulting binary yourself.
- For the single-core v2.0 builds the only difference from the active build of the same variant is `CONFIG_FREERTOS_UNICORE: "y"`, which pins FreeRTOS to a single core; pins, entity names, defaults and behaviour are identical.
- An archived single-core build still runs on a dual-core board (one core stays idle), but there is no reason to choose one there — use the active dual-core build instead. The archived v1.0 builds are for v1.0 boards, which have no 1-Wire or radar interface.

## How to decide what to flash

```text
Controller in hand (every unit sold after 2026-11-12 is dual-core)
  ├─ v2.0 board, no temperature/radar needs ─────────────────────────→ v2.0 Basic (dual-core)
  ├─ v2.0 board, need temperature control without HA ────────────────→ v2.0 DS18B20 (dual-core)
  ├─ v2.0 board, need human presence detection ──────────────────────→ v2.0 DS18B20 + radar (dual-core)
  ├─ v1.0 board ─────────────────────────────────────────────────────→ archived v1.0 build (compile it locally)
  └─ older single-core board (shipped before 2026-11-12) ────────────→ archived single-core build (compile it locally)
```

> **The rule is one-directional.** A single-core board cannot boot dual-core firmware, so it needs the matching archived single-core build. The other direction is safe: a dual-core board can also run an archived single-core build (one core simply stays idle), but the active dual-core build is the default and the better choice.

> **Do not reach for a single-core build "to be safe" any more.** Before 2026-11-12 that was the cautious choice; since then every unit sold is dual-core and the v2.0 builds in Releases are dual-core only. Flashing a current release on a pre-2026-11-12 single-core board is the one combination that fails to boot — see [Troubleshooting](Troubleshooting-EN#device-does-not-boot--hotspot-not-found).

Within one language, the **archived** v1.0 single-core and the **archived** v2.0 Basic configurations are byte-for-byte identical (`firmware/en/archive/v1.0/single-core/config.yaml` == `firmware/en/archive/v2.0/single-core/basic/config.yaml`, and the same holds for the `zh/` pair); only the directory differs, because they belong to different hardware revisions. The active v2.0 Basic is a different, dual-core build. Across languages the files differ only in entity names and comments.

## Release artifacts

The firmware is compiled automatically by GitHub Actions and published on [Releases](https://github.com/YUAXI/HomeAssistant-PWM-Fan-Controlx4/releases), tagged with the build date (e.g. `2026.10.14`). Each release contains **6 builds** — 3 active variants × 2 languages — and each build ships 3 kinds of file (18 files in total):

| File suffix | Contents | Used for |
|:---------|:-----|:-------|
| `*.firmware.bin` | application partition only | OTA upgrades, `esptool` write at `0x10000` |
| `*.firmware.factory.bin` | bootloader + partition table + application | first flashing / unbricking, write at `0x0` |
| `*.firmware.ota.bin` | OTA-only image | ESPHome Dashboard / `esphome upload` |

The English build is the primary/recommended download; the `-zh` build keeps the original Chinese entity names. Release names and their config files:

| Version | English release | Chinese release | Config (English) | Config (Chinese) |
|:--------|:----------------|:----------------|:-----------------|:-----------------|
| v2.0 Basic | `v2.0-basic-en` | `v2.0-basic-zh` | `firmware/en/v2.0/dual-core/basic/config.yaml` | `firmware/zh/v2.0/dual-core/basic/config.yaml` |
| v2.0 DS18B20 | `v2.0-ds18b20-en` | `v2.0-ds18b20-zh` | `firmware/en/v2.0/dual-core/ds18b20/config.yaml` | `firmware/zh/v2.0/dual-core/ds18b20/config.yaml` |
| v2.0 DS18B20 + radar | `v2.0-ds18b20-radar-en` | `v2.0-ds18b20-radar-zh` | `firmware/en/v2.0/dual-core/ds18b20-radar/config.yaml` | `firmware/zh/v2.0/dual-core/ds18b20-radar/config.yaml` |

File names are `<release name>.<file suffix>`, for example `v2.0-ds18b20-en.firmware.factory.bin` (English) or `v2.0-ds18b20-radar-zh.firmware.bin` (Chinese).

> The 3 variants are the same in both languages, so pick by hardware first, then by language. Switching language later changes the entity names and therefore the HA `entity_id`s.
>
> **v1.0 and single-core builds are not published.** There is no v1.0 or single-core row above on purpose: the whole v1.0 line and the single-core v2.0 builds were withdrawn when v2.0 became dual-core. For such a board, compile the archived config yourself (next section).

## Custom compilation

Changing the Wi-Fi, the entity names or the API key all require compiling the firmware yourself. Recommended flow (the same works for any `firmware/en/...` or `firmware/zh/...` config):

```bash
pip install esphome
esphome config firmware/en/v2.0/dual-core/ds18b20/config.yaml   # validate the syntax first
esphome compile firmware/en/v2.0/dual-core/ds18b20/config.yaml
esphome upload  firmware/en/v2.0/dual-core/ds18b20/config.yaml
```

Swap `ds18b20` for `basic` or `ds18b20-radar` to build the other two v2.0 variants.

For an older **single-core** board, point the same commands at the archived config:

```bash
esphome config firmware/en/archive/v2.0/single-core/ds18b20/config.yaml
esphome compile firmware/en/archive/v2.0/single-core/ds18b20/config.yaml
esphome upload  firmware/en/archive/v2.0/single-core/ds18b20/config.yaml
```

### Pre-setting Wi-Fi (skip provisioning)

```yaml
wifi:
  ssid: "your-ssid"
  password: "your-password"
  ap:                       # keep the AP as a fallback
    ssid: "ESP32-Fan-22810"
    password: ""
```

### Changing the API key and OTA password

```yaml
api:
  encryption:
    key: "paste your own 32-byte base64 key"
ota:
  - platform: esphome
    password: "paste your own password"
```

> After changing the API key, the old entry in HA fails authentication and you have to delete the device and add it again. Generate a key with: `openssl rand -base64 32`.

### Changing entity names

```yaml
fan:
  - platform: speed
    output: fan1_pwm
    name: "Rack Fan 1"      # change this
```

Mind the knock-on effects:

1. The `entity_id` in HA changes with it (e.g. `fan.esp32_pwm_22810_a1b2c3_rack_fan_1`), so automations and dashboards that reference it need updating too;
2. The HTTP API URL paths change as well (see [HTTP API](HTTP-API-EN));
3. With `name_add_mac_suffix: true` the device-name suffix is unaffected, so multiple devices still don't collide.

> **Entity naming guidance**: the English firmware now ships with ASCII names (`Fan 1`, `Fan 1 RPM`, `Temp A`, `Uptime` …), which is the recommended convention — HTTP API paths then only need spaces encoded as `%20`. The Chinese edition (`firmware/zh/`) deliberately keeps the original Chinese names for backward compatibility, so its paths must be fully percent-encoded. Keep names ASCII if you write your own config, and do not mix the two naming schemes on one device if scripts depend on the paths.

### Giving each device its own name

```yaml
substitutions:
  device_name: fanctrl-01

esphome:
  name: ${device_name}
  name_add_mac_suffix: false
```

With the suffix enabled, `name` may be at most 24 characters (the ESPHome hostname limit is 31, of which the suffix takes 7) and `esp32pwm22810` is far below the limit.

### Adding your own sensors

Taking I²C temperature and humidity as an example, just add it anywhere (it appears in HA alongside the fan entities):

```yaml
i2c:
  sda: GPIO27
  scl: GPIO2      # GPIO2 is a strapping pin, make sure it is not pulled low at boot

sensor:
  - platform: sht3xd
    temperature:
      name: "Rack Temperature"
    humidity:
      name: "Rack Humidity"
    update_interval: 30s
```

> Before you start, make sure the target pin is not already taken by the fans: GPIO16–19 (PWM), GPIO32/33/25/26 (RPM), GPIO21/22/23/13 (power switches), GPIO14 (1-Wire), GPIO4/5 (radar serial). The full table is in [Hardware](Hardware-EN#gpio-assignments).

## CI build flow

`.github/workflows/build.yml`:

| Stage | Behaviour |
|:-----|:-----|
| Trigger | push to `master`, or manual `workflow_dispatch` on the Actions page |
| Matrix | 6 configs (3 active variants × 2 languages: `-en` and `-zh`) compiled in parallel, `fail-fast: false` (independent of each other) |
| Environment | `ubuntu-latest` + Python 3.11 + `pip install esphome` (always the latest) |
| Cache | `~/.esphome`, keyed on the hash of `firmware/**/config.yaml` |
| Compile | `esphome compile <config>` |
| Collect | find `firmware*.bin` under `<config dir>/.esphome` and rename it to `<release name>.<original name>` |
| Verify | before publishing, the workflow checks that both `-en` and `-zh` images exist for all three v2.0 variants and fails otherwise |
| Publish | `softprops/action-gh-release@v2`, tag is the date of the day, attaching the bins of all 6 builds |

The matrix covers `v2.0-basic`, `v2.0-ds18b20` and `v2.0-ds18b20-radar`, each in `-en` and `-zh`; the `archive/` configs (the whole v1.0 line and the single-core v2.0 builds) are deliberately absent, which is what keeps those binaries out of Releases.

Two things follow from this:

- CI uses the latest ESPHome, so **an upstream major-version bump can break the build**; when debugging locally, run `pip install -U esphome` first to reproduce it.
- Release tags are dates, so triggering the workflow several times in one day updates the same release (same tag name); that is expected behaviour.

## Upgrading and rolling back

| Action | How |
|:-----|:-----|
| Upgrade from HA | ESPHome integration → device → three dots → Update (only available when the device is compiled and managed by HA) |
| Upgrade from the CLI | `esphome upload <config> --device <IP>` |
| Upgrade from the web panel | the default `web_server` config does not provide OTA; use one of the two methods above |
| Switch language edition | flash the matching `-en` / `-zh` build. ⚠️ The entity names change, so HA creates new entities: delete the old device entry and re-add it, then update dashboards and automations |
| Rollback | download the `.firmware.ota.bin` of an older release (same version **and** same language) and upload it again; rolling back across hardware versions is pointless |
| Unbrick | USB + `esptool` write `.firmware.factory.bin` to `0x0`, holding BOOT to enter download mode if necessary |

Before upgrading:

1. Make sure the new firmware matches the hardware revision: every unit sold after 2026-11-12 is dual-core, so a current release fits it; if you own an older single-core board, flash the archived single-core build instead (see [Archived builds](#archived-builds)) and keep the same language edition unless you intend to migrate;
2. Note the current `T-Min` / `T-Max` and other parameters (`restore_value` keeps them in the device NVS; a normal OTA preserves them, but a flash that changes the partition table may reset them);
3. Avoid unattended remote OTA — a power cut means an on-site unbrick.

> Rolling back to a single-core build is only possible with a binary you compiled yourself: the old single-core artifacts are no longer on Releases. Keep your own `.firmware.factory.bin` around if you maintain a pre-2026-11-12 unit.
