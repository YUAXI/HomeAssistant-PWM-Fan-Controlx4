# Changelog

[← Home](Home-EN) · [中文](Changelog) · **English**

This page records behaviour changes to the firmware and hardware. **Entries marked ⚠️ change how the device behaves in Home Assistant — read them before upgrading.**

## Firmware

| Date | Change | Impact |
|:-----|:-----|:-----|
| 2026-10-14 | `name_add_mac_suffix: true` enabled in all builds | ⚠️ The device name becomes `esp32pwm22810-<mac3>` and every `entity_id` changes; the old entry must be deleted and re-added. The upside is that the same firmware can be flashed to multiple devices and used in HA at the same time |
| 2026-08-16 | When the temperature ≤ `T-Min` the fan is **powered off and comes to a full stop**, and restarts automatically once the temperature recovers | ⚠️ At low temperatures the fan goes from "always spinning slowly" to "fully stopped"; if you prefer constant spinning, lower `T-Min` or raise `F-Min` and judge for yourself |
| 2026-07-10 | On a DS18B20 read error, keep the current fan speed; removed the "force full speed on error" protection | No more sudden full speed when a probe drops out; cooling capacity is reduced during the fault, so consider adding a temperature alert on the HA side |
| 2026-07-01 | Bluetooth proxy (BLE Proxy) added to all builds | The device becomes a BLE gateway; memory usage increases slightly |
| 2026-07-01 | CI compiles and publishes Releases automatically; prebuilt firmware removed from the repository | Firmware is now downloaded from [Releases](https://github.com/YUAXI/HomeAssistant-PWM-Fan-Controlx4/releases) instead of being distributed with the repository |
| 2026-06 | Temperature-control parameters (`T-Min`/`T-Max`/`F-Min`/`F-Max`) and temperature source bindings now survive power loss | Parameters are kept across reboots |
| v2.0 | Added the DS18B20 temperature-control firmware and the LD2402G radar firmware | The DS18B20 build provides 4 temperature channels, 16 temperature-control parameters, and a 5-second local closed loop; the radar build additionally provides presence detection and distance thresholds |
| v1.0 | Web interface, HTTP REST API, diagnostic entities | Can be used without HA |

## Hardware

| Version | Date | Change |
|:-----|:-----|:-----|
| v2.0 | 2026-06-27 (BOM revision) | Added a 1-Wire temperature interface (3.5 mm 3P terminal) and a 4-pin expansion header (5V/GND/GPIO5/GPIO4); changed the expansion interface to a 3-pin terminal form factor; reserved for temperature control and radar |
| v2.0 | — | MCU, fan channels, and power design are identical to v1.0 (ESP32-WROOM-32, 4 × TPS22810, TPS5430 + AMS1117) |
| v1.0 | 2026-05-21 (BOM revision) | First public release: 4-channel fan control, Web, HTTP API, diagnostics, BLE Proxy |

## Documentation

| Date | Change |
|:-----|:-----|
| 2026-11-09 | Added a bilingual Chinese/English Wiki (`docs/wiki/`, 13 pages × 2 languages); added a documentation index to the README; provided `scripts/sync-wiki.ps1` / `scripts/sync-wiki.sh` for one-command publishing to the GitHub Wiki. |

## Upgrade notes

### Upgrading from "no MAC suffix" firmware to the current version

1. In HA, **delete** the old ESPHome entry first (do not use "migrate", or it will fight with the new device);
2. Flash the new firmware over OTA or USB;
3. Add the device again; its name now carries the MAC suffix;
4. Anywhere a dashboard/automation references the old `entity_id` must be pointed at the new entity (you can first use "Developer Tools → Entities" to search for and confirm the new ID).

### Upgrading from `v1.0` to `v2.0`

- The hardware differs: the v1.0 board has no 1-Wire or radar interface, so after flashing v2.0 firmware the temperature/radar entities will always be `unknown` (the features are unavailable, but fan control is unaffected);
- Conversely, flashing v1.0 single-core firmware on a v2.0 board only removes the extended features; fan control works normally.

### About "reflashing the same version"

The Release tag is the build date, and triggering CI several times on the same day updates the same Release. If you need a traceable version, record the tag you downloaded and the `ESPHome 版本` ("ESPHome version") diagnostic entity.

## Compatibility matrix

| Firmware | v1.0 hardware | v2.0 hardware |
|:-----|:---------:|:---------:|
| v1.0 dual-core | ⚠️ dual-core boards only | ⚠️ dual-core boards only |
| v1.0 single-core | ✅ | ✅ |
| v2.0 Basic | ✅ (no extended features) | ✅ |
| v2.0 DS18B20 | ⚠️ runs, but no temperature interface | ✅ |
| v2.0 DS18B20 + radar | ⚠️ runs, but no radar interface | ✅ |

> Within a column, "✅" means full functionality and "⚠️" means it runs but lacks the corresponding hardware interface. Single-core firmware also runs normally on dual-core chips.
