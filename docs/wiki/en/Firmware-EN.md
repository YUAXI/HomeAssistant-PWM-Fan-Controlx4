# Firmware Versions and Compilation

[← Home](Home-EN) · [中文](Firmware) · **English**

## Version matrix

| Firmware | Processor | 4 fans | RPM | Temperature closed loop | Radar | BLE Proxy | Config file |
|:-----|:------:|:--------:|:----:|:--------:|:----:|:---------:|:---------|
| v1.0 dual-core | Dual-core | ✅ | ✅ | - | - | ✅ | `firmware/v1.0/dual-core/config.yaml` |
| v1.0 single-core | Single-core | ✅ | ✅ | - | - | ✅ | `firmware/v1.0/single-core/config.yaml` |
| v2.0 Basic | Single-core | ✅ | ✅ | - | - | ✅ | `firmware/v2.0/single-core/basic/config.yaml` |
| v2.0 DS18B20 | Single-core | ✅ | ✅ | ✅ | - | ✅ | `firmware/v2.0/single-core/ds18b20/config.yaml` |
| v2.0 + radar | Single-core | ✅ | ✅ | ✅ | ✅ | ✅ | `firmware/v2.0/single-core/ds18b20-radar/config.yaml` |

The config skeleton shared by all versions:

| Config key | Value | Effect |
|:-------|:---|:-----|
| `esp32.board` | `esp32dev` | ESP32-WROOM-32 |
| `esp32.variant` | `ESP32` | — |
| `esp32.framework` | `esp-idf` | not Arduino |
| `CONFIG_FREERTOS_UNICORE` | `y` for single-core builds | enable only 1 core |
| `CONFIG_ESP_SYSTEM_PANIC_PRINT_REBOOT` | `y` | automatic reboot after a crash |
| `logger.level` | `INFO` | serial / web log level |
| `web_server.port` | `80` | web panel and REST API |
| `bluetooth_proxy.active` | `true` | actively connect to BLE devices |

## How to decide what to flash

```text
Device in hand
  ├─ can confirm it is a dual-core ESP32 and want more performance ──→ v1.0 dual-core
  ├─ unsure whether single-core or dual-core ────────────────────────→ single-core firmware (v1.0 single-core or any v2.0)
  ├─ v2.0 hardware but no temperature/radar needs ───────────────────→ v2.0 Basic
  ├─ need temperature control without HA ────────────────────────────→ v2.0 DS18B20
  └─ need human presence detection ──────────────────────────────────→ v2.0 DS18B20 + radar
```

> **Why single-core firmware is safer**: `CONFIG_FREERTOS_UNICORE: "y"` only makes FreeRTOS schedule a single core, and it still runs fine on a dual-core ESP32; the other way round, dual-core firmware on a device that can only run one core fails to boot. **So when in doubt, pick single-core.**
>
> **Retail devices are usually single-core designs** and can only run `v1.0 single-core` or any `v2.0` firmware. Flashing `v1.0 dual-core` firmware leaves the device unable to boot, and the only recovery is re-flashing over USB.

v1.0 single-core and v2.0 Basic have byte-for-byte identical config file contents (only the directory differs); the difference is just which hardware version they belong to. v2.0 Basic is the better default choice for v2.0 boards.

## Release artifacts

The firmware is compiled automatically by GitHub Actions and published on [Releases](https://github.com/YUAXI/HomeAssistant-PWM-Fan-Controlx4/releases), tagged with the build date (e.g. `2026.10.14`). Each release contains 5 versions × 3 kinds of file:

| File suffix | Contents | Used for |
|:---------|:-----|:-------|
| `*.firmware.bin` | application partition only | OTA upgrades, `esptool` write at `0x10000` |
| `*.firmware.factory.bin` | bootloader + partition table + application | first flashing / unbricking, write at `0x0` |
| `*.firmware.ota.bin` | OTA-only image | ESPHome Dashboard / `esphome upload` |

File names look like `v2.0-ds18b20.v2.0-ds18b20.firmware.factory.bin` (`<release name>.<ESPHome artifact name>.bin`).

| Release version name | Config file |
|:---------------|:---------|
| `v1.0-dual-core` | `firmware/v1.0/dual-core/config.yaml` |
| `v1.0-single-core` | `firmware/v1.0/single-core/config.yaml` |
| `v2.0-basic` | `firmware/v2.0/single-core/basic/config.yaml` |
| `v2.0-ds18b20` | `firmware/v2.0/single-core/ds18b20/config.yaml` |
| `v2.0-ds18b20-radar` | `firmware/v2.0/single-core/ds18b20-radar/config.yaml` |

## Custom compilation

Changing the Wi-Fi, the entity names or the API key all require compiling the firmware yourself. Recommended flow:

```bash
pip install esphome
esphome config firmware/v2.0/single-core/basic/config.yaml   # validate the syntax first
esphome compile firmware/v2.0/single-core/basic/config.yaml
esphome upload  firmware/v2.0/single-core/basic/config.yaml
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
    name: "机柜风扇"      # change this
```

Mind the knock-on effects:

1. The `entity_id` in HA changes with it (e.g. `fan.xxx_ji_gui_feng_shan`), so automations and dashboards that reference it need updating too;
2. The HTTP API URL paths change as well (see [HTTP API](HTTP-API-EN));
3. With `name_add_mac_suffix: true` the device-name suffix is unaffected, so multiple devices still don't collide.

### Giving each device its own name

```yaml
substitutions:
  device_name: fanctrl-01

esphome:
  name: ${device_name}
  name_add_mac_suffix: false
```

Chinese names read better but force URL encoding; if you plan to use the HTTP API heavily, prefer ASCII names (e.g. `fan 1`). With the suffix enabled, `name` may be at most 24 characters (the ESPHome hostname limit is 31, of which the suffix takes 7) and `esp32pwm22810` is far below the limit.

### Adding your own sensors

Taking I²C temperature and humidity as an example, just add it anywhere (it appears in HA alongside the fan entities):

```yaml
i2c:
  sda: GPIO27
  scl: GPIO2      # GPIO2 is a strapping pin, make sure it is not pulled low at boot

sensor:
  - platform: sht3xd
    temperature:
      name: "机柜温度"
    humidity:
      name: "机柜湿度"
    update_interval: 30s
```

> Before you start, make sure the target pin is not already taken by the fans: GPIO16–19 (PWM), GPIO32/33/25/26 (RPM), GPIO21/22/23/13 (power switches), GPIO14 (1-Wire), GPIO4/5 (radar serial). The full table is in [Hardware](Hardware-EN#gpio-assignments).

## CI build flow

`.github/workflows/build.yml`:

| Stage | Behaviour |
|:-----|:-----|
| Trigger | push to `master`, or manual `workflow_dispatch` on the Actions page |
| Matrix | 5 configs compiled in parallel, `fail-fast: false` (independent of each other) |
| Environment | `ubuntu-latest` + Python 3.11 + `pip install esphome` (always the latest) |
| Cache | `~/.esphome`, keyed on the hash of `firmware/**/config.yaml` |
| Compile | `esphome compile <config>` |
| Collect | find `firmware*.bin` under `<config dir>/.esphome` and rename it to `<release name>.<original name>` |
| Publish | `softprops/action-gh-release@v2`, tag is the date of the day, attaching the bins of all 5 versions |

Two things follow from this:

- CI uses the latest ESPHome, so **an upstream major-version bump can break the build**; when debugging locally, run `pip install -U esphome` first to reproduce it.
- Release tags are dates, so triggering the workflow several times in one day updates the same release (same tag name); that is expected behaviour.

## Upgrading and rolling back

| Action | How |
|:-----|:-----|
| Upgrade from HA | ESPHome integration → device → three dots → Update (only available when the device is compiled and managed by HA) |
| Upgrade from the CLI | `esphome upload <config> --device <IP>` |
| Upgrade from the web panel | the default `web_server` config does not provide OTA; use one of the two methods above |
| Rollback | download the `.firmware.ota.bin` of an older release and upload it again; rolling back across hardware versions is pointless |
| Unbrick | USB + `esptool` write `.firmware.factory.bin` to `0x0`, holding BOOT to enter download mode if necessary |

Before upgrading:

1. Make sure the new firmware matches the hardware revision (especially dual-core / single-core);
2. Note the current `T-Min` / `T-Max` and other parameters (`restore_value` keeps them in the device NVS; a normal OTA preserves them, but a flash that changes the partition table may reset them);
3. Avoid unattended remote OTA — a power cut means an on-site unbrick.
