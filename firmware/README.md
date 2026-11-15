# Firmware

ESPHome configurations for the 4-channel PWM fan controller. **All controllers
sold after 2026-11-12 use the dual-core design**, so the active firmware is v2.0
built for dual-core operation. The whole v1.0 line and all single-core v2.0
configurations are archived under `archive/` for devices shipped earlier.

## Languages

| Folder | Entity names | Language | Role |
|:-------|:-------------|:---------|:-----|
| [`en/`](./en/) | English (`Fan 1`, `Temp A`, `Uptime`, …) | English | **Primary / recommended** |
| [`zh/`](./zh/) | Chinese (`风扇 1`, `温度 A`, `设备运行时间`, …) | Chinese | Chinese edition |

Both trees are functionally identical — same pins, same logic, same node name
(`esp32pwm22810`). Only the entity names (and therefore the Home Assistant
`entity_id`s and HTTP API paths) differ.

## Active builds (v2.0, dual-core)

| Version | CPU | Folder | Config | Release artifact |
|:--------|:---:|:-------|:-------|:-----------------|
| v2.0 Basic | Dual-core | `en/v2.0/dual-core/basic/` · `zh/v2.0/dual-core/basic/` | `config.yaml` | `v2.0-basic-en` · `v2.0-basic-zh` |
| v2.0 DS18B20 | Dual-core | `en/v2.0/dual-core/ds18b20/` · `zh/v2.0/dual-core/ds18b20/` | `config.yaml` | `v2.0-ds18b20-en` · `v2.0-ds18b20-zh` |
| v2.0 DS18B20 + radar | Dual-core | `en/v2.0/dual-core/ds18b20-radar/` · `zh/v2.0/dual-core/ds18b20-radar/` | `config.yaml` | `v2.0-ds18b20-radar-en` · `v2.0-ds18b20-radar-zh` |

All active variants use the ESP32 DevKit board with the ESP-IDF framework,
leave FreeRTOS on both cores, and enable `name_add_mac_suffix: true`, so one
binary can be flashed to any number of devices without them colliding in Home
Assistant.

## Archived builds

Archived configurations are kept for existing hardware but are **no longer
built by CI and no longer published as release artifacts**. Compile them from
source if you need one.

| Version | CPU | Folder | Notes |
|:--------|:---:|:-------|:------|
| v1.0 dual-core | Dual-core | `en/archive/v1.0/dual-core/` · `zh/archive/v1.0/dual-core/` | v1.0 line, archived |
| v1.0 single-core | Single-core | `en/archive/v1.0/single-core/` · `zh/archive/v1.0/single-core/` | v1.0 line, archived |
| v2.0 Basic (single-core) | Single-core | `en/archive/v2.0/single-core/basic/` · `zh/archive/v2.0/single-core/basic/` | v2.0 boards shipped before 2026-11-12 |
| v2.0 DS18B20 (single-core) | Single-core | `en/archive/v2.0/single-core/ds18b20/` · `zh/archive/v2.0/single-core/ds18b20/` | Same |
| v2.0 DS18B20 + radar (single-core) | Single-core | `en/archive/v2.0/single-core/ds18b20-radar/` · `zh/archive/v2.0/single-core/ds18b20-radar/` | Same |

For the single-core v2.0 builds the only difference from the active dual-core
build is that `CONFIG_FREERTOS_UNICORE: "y"` is set, so FreeRTOS schedules a
single core.

> **Hardware rule:** a single-core board cannot boot dual-core firmware, so
> owners of a pre-2026-11-12 single-core controller must flash the matching
> archived single-core build. A dual-core board can run either edition (the
> single-core build just leaves one core idle).

## Build

```bash
pip install esphome

# English v2.0 DS18B20, dual-core (primary build)
esphome config  firmware/en/v2.0/dual-core/ds18b20/config.yaml
esphome compile firmware/en/v2.0/dual-core/ds18b20/config.yaml

# Chinese equivalent
esphome compile firmware/zh/v2.0/dual-core/ds18b20/config.yaml

# Archived build (only for older hardware)
esphome compile firmware/en/archive/v2.0/single-core/ds18b20/config.yaml
esphome compile firmware/en/archive/v1.0/dual-core/config.yaml
```

The build output lands in `<config dir>/.esphome/build/esp32pwm22810/.pioenvs/esp32pwm22810/`:

| File | Use |
|:-----|:----|
| `firmware.bin` | standard image, flash at `0x10000` or use for OTA |
| `firmware.factory.bin` | factory image, flash at `0x0` for first flashing / unbricking |
| `firmware.ota.bin` | OTA-only image for ESPHome Dashboard / `esphome upload` |

`.esphome/` build directories and local `dist/` output are ignored by Git.
GitHub Actions compiles the six active builds in parallel (3 variants × 2
languages) and attaches them to the dated release — see
[`.github/workflows/build.yml`](../.github/workflows/build.yml).
