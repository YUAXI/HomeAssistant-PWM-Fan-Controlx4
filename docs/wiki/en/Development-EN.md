# Development Guide

[← Home](Home-EN) · [中文](Development) · **English**

## Repository layout

```text
HomeAssistant-PWM-Fan-Controlx4/
├── readme.md                       # English overview (primary, user-facing)
├── README_ZH.md                    # Chinese overview
├── LICENSE                         # MIT
├── .github/workflows/build.yml     # 6-build matrix (3 active variants × 2 languages) + automatic Release
├── docs/
│   ├── images/                     # image assets (hardware photos, screenshots, diagrams, donation QR)
│   └── wiki/                       # source files for this Wiki (zh/ en/ + sync script)
├── firmware/
│   ├── README.md                   # firmware catalogue: active vs archived, build commands
│   ├── en/                         # English firmware (primary language)
│   │   ├── v2.0/dual-core/                     # active dual-core builds
│   │   │   ├── basic/config.yaml
│   │   │   ├── ds18b20/config.yaml             # + 1-Wire + temperature-control entities and algorithm
│   │   │   └── ds18b20-radar/config.yaml       # + UART radar parsing + radar tuning
│   │   └── archive/                            # NOT built by CI, NOT in Releases
│   │       ├── v1.0/{dual-core,single-core}/config.yaml
│   │       └── v2.0/single-core/{basic,ds18b20,ds18b20-radar}/config.yaml
│   └── zh/                         # Chinese firmware: same layout and features, Chinese entity names
│       ├── v2.0/dual-core/{basic,ds18b20,ds18b20-radar}/config.yaml
│       └── archive/{v1.0/{dual-core,single-core}, v2.0/single-core/...}
└── hardware/
    ├── v1.0/{pcb,3d-models}/
    └── v2.0/{pcb,3d-models}/
```

## Anatomy of a config file

All firmware variants share the same skeleton, in this order (keep that order when modifying, so diffs stay easy to read):

| Section | Purpose |
|:---|:-----|
| `esphome` | node name, `name_add_mac_suffix`, `friendly_name`, (radar build) `on_boot` initialisation |
| `esp32` | board, ESP-IDF framework, `CONFIG_FREERTOS_UNICORE` (only in the archived single-core builds), panic reboot |
| `logger` | log level `INFO` |
| `api` | native API + encryption key |
| `ota` | ESPHome OTA + password |
| `wifi` / `captive_portal` | hotspot fallback + provisioning page |
| `esp32_ble_tracker` / `bluetooth_proxy` | BLE proxy |
| `web_server` | web panel and REST API on port 80 |
| `one_wire` | DS18B20 bus (GPIO14, temperature build only) |
| `uart` | radar serial + `debug.sequence` parsing (radar build only) |
| `output` | 4 × LEDC 25 kHz PWM |
| `switch` | 4 × fan power switches (`internal: true`, `ALWAYS_OFF`) |
| `select` | 4 × temperature source bindings (temperature build only) |
| `number` | 16 temperature-control parameters (+ 2 radar thresholds) |
| `interval` | 5-second temperature-control main loop |
| `binary_sensor` / `sensor` / `text_sensor` | radar state, RPM, temperature, diagnostics |
| `fan` | 4 × speed fan, `on_turn_on/off` drives the power switches |

## Adding a 5th fan

Assume the new channel uses GPIO15 (PWM), GPIO34 (tach, input only), GPIO27 (power switch):

```yaml
output:
  - platform: ledc
    pin: GPIO15
    id: fan5_pwm
    frequency: 25000Hz

switch:
  - platform: gpio
    pin: GPIO27
    id: fan5_pwr
    internal: true
    restore_mode: ALWAYS_OFF

sensor:
  - platform: pulse_counter
    pin:
      number: GPIO34
      mode: INPUT
    name: "Fan 5 RPM"
    id: fan5_rpm
    unit_of_measurement: "RPM"
    update_interval: 4s
    count_mode: {rising_edge: DISABLE, falling_edge: INCREMENT}
    internal_filter: 13us
    filters:
      - multiply: 0.5

fan:
  - platform: speed
    output: fan5_pwm
    name: "Fan 5"
    id: my_fan5
    speed_count: 100
    restore_mode: RESTORE_DEFAULT_OFF
    on_turn_on:
      - switch.turn_on: fan5_pwr
    on_turn_off:
      - switch.turn_off: fan5_pwr
```

To hook it into temperature control you also need a matching `select` (`f5_source`), 4 × `number` (`f5_t_min`, etc.), and a copied `s5` branch in the `interval` lambda (replace `my_fan1` with `my_fan5` and rename the variables).

> The ESP32 has limited free pins (see the [hardware reference](Hardware-EN#gpio-assignments)). For 8 channels, add an IO expander chip instead of squeezing GPIOs.

## Building locally

```bash
# Option 1: local Python (recommended, matches CI)
python -m venv .venv && . .venv/bin/activate      # Windows: .venv\Scripts\activate
pip install esphome
esphome config  firmware/en/v2.0/dual-core/basic/config.yaml   # syntax/pin validation
esphome compile firmware/en/v2.0/dual-core/basic/config.yaml
esphome upload  firmware/en/v2.0/dual-core/basic/config.yaml

# Archived builds (older boards only; not built by CI)
esphome compile firmware/en/archive/v2.0/single-core/basic/config.yaml   # single-core legacy board
esphome compile firmware/en/archive/v1.0/dual-core/config.yaml        # v1.0 board

# Option 2: Docker (if you don't want to pollute your environment)
docker run --rm -v "$PWD":/config -w /config \
  ghcr.io/esphome/esphome compile firmware/en/v2.0/dual-core/basic/config.yaml
```

Build output location: `<config dir>/.esphome/build/<node name>/`, e.g. `firmware/en/v2.0/dual-core/basic/.esphome/build/esp32pwm22810/` (the `firmware/zh/` and `firmware/en/archive/` trees have the same layout; this directory is already ignored by `.gitignore`).

`esphome config` is the cheapest check available — it catches 90 % of YAML / pin / component parameter errors before you flash.

## Debugging tips

| Need | Method |
|:-----|:-----|
| View boot and runtime logs | `esphome logs <config>`, or the log area at the bottom of the web panel |
| View 1-Wire addresses | `logger.level: DEBUG`; the boot log lists the device addresses |
| View raw radar bytes | `uart.debug` is already enabled in the radar build, so the log prints transmitted and received data |
| Build fails on Windows with a "path too long" / `WinError 3` while installing libsodium | Copy the config to a short path (for example `C:\fw`) and compile there, or enable Windows long-path support (`LongPathsEnabled`). CI runs on Ubuntu and is unaffected |
| Temporarily raise the log level | `logger.level: DEBUG` (note that flooding the log will slow the device down) |
| Validate pins | `esphome config` reports pin conflicts |
| Step through temperature control | Temporarily change `interval: 5s` to `1s` and watch the response (remember to change it back) |

## CI and releases

| Item | Value |
|:---|:---|
| Workflow | `.github/workflows/build.yml` |
| Trigger | push to `master`, `workflow_dispatch` |
| Matrix | 6 builds = 3 active variants (`v2.0-basic`, `v2.0-ds18b20`, `v2.0-ds18b20-radar`) × 2 languages (`-en`, `-zh`); the `archive/` configs are not in the matrix, so no v1.0 or single-core binary is ever published |
| Failure policy | `fail-fast: false`, so one failing variant does not affect the others |
| Cache | `~/.esphome`, keyed by the hash of `firmware/**/config.yaml` |
| Artifacts | `firmware*.bin` for each build, renamed to `<release name>.<original filename>` (e.g. `v2.0-ds18b20-en.firmware.factory.bin`) |
| Release | all 6 builds merged, a Release created with the date (`%Y.%-m.%-d`) as the tag; the `-en` build is the primary download |

**Adding a firmware variant** requires 4 coordinated changes; missing any one of them leaves the docs and CI out of sync:

1. Create the directory and write `config.yaml` in **both** `firmware/en/` and `firmware/zh/` (copy the closest variant, then translate the entity names in the Chinese copy). Put it under `vX.Y/dual-core/...` if it is an active dual-core build; anything that must keep `CONFIG_FREERTOS_UNICORE: "y"` goes under `archive/` and is not released;
2. Add two `name` + `path` rows (`-en` and `-zh`) to `matrix.include` in `.github/workflows/build.yml` — active configs only;
3. The firmware tables and Release cross-reference tables in `readme.md` (English), `README_ZH.md` (Chinese) and `firmware/README.md`;
4. The tables in [Home](Home-EN), [Firmware](Firmware-EN), and [Entities](Entities-EN) of this Wiki — and the matching Chinese wiki pages.

## Commits and branches

| Type | Prefix | Example |
|:-----|:-----|:-----|
| New feature | `feat:` | `feat: add radar stationary-target filtering` |
| Fix | `fix:` | `fix: fix turn_off compile error` |
| Docs | `docs:` | `docs: add OTA notes` |
| CI | `ci:` | `ci: fix firmware collection path` |
| Chores | `chore:` | `chore: remove prebuilt firmware` |

- The main branch is `master`; you can commit to `master` directly or open a PR, either is fine;
- After changing firmware configuration, run `esphome config` + `esphome compile` locally and make sure both pass before committing;
- For behaviour changes (e.g. stop thresholds, parameter defaults), also update the changelog table in `readme.md` (and `README_ZH.md`) and the [changelog](Changelog-EN) in this Wiki.

## Documentation (Wiki) maintenance

The source files for this Wiki live in `docs/wiki/`:

```text
docs/wiki/
├── README.md          # how to publish / sync to the GitHub Wiki
├── zh/                # Chinese pages (Home.md, Firmware.md …)
└── en/                # English pages (Home-EN.md, Firmware-EN.md …)
```

Conventions:

- Every page exists in both Chinese and English, named `<Page>.md` / `<Page>-EN.md`;
- The English pages are the primary documentation and track `firmware/en/`; when behaviour changes, update the English page first and then mirror it to `zh/`;
- Images inside pages always use absolute `raw.githubusercontent.com` URLs (GitHub Wiki does not resolve repository-relative paths);
- When adding a page, update `zh/_Sidebar.md`, `en/_Sidebar.md`, and the navigation table on `Home` at the same time;
- See `docs/wiki/README.md` for the publishing process (the GitHub Wiki home page must be created in the web UI first; after that the script can push).
