# Changelog

[← Home](Home-EN) · [中文](Changelog) · **English**

This page records behaviour changes to the firmware and hardware. **Entries marked ⚠️ change how the device behaves in Home Assistant — read them before upgrading.**

## Firmware

| Date | Change | Impact |
|:-----|:-----|:-----|
| 2026-11-15 | **The entire v1.0 line is archived**: `v1.0` dual-core and single-core configs moved to `firmware/*/archive/v1.0/`. Releases now ship **6 builds** (3 active v2.0 variants × 2 languages, i.e. 18 files); v1.0 and single-core artifacts are no longer published | ⚠️ There is no v1.0 download any more. A v1.0 board must be flashed with a locally compiled archived v1.0 build — the current v2.0 release does not fit it |
| 2026-11-14 | **v2.0 is now dual-core**: every controller sold after 2026-11-12 uses the dual-core design, so the active v2.0 configs moved to `firmware/*/v2.0/dual-core/{basic,ds18b20,ds18b20-radar}/config.yaml` and the single-core configs were archived under `firmware/*/archive/`. Releases at that point shipped **8 builds** (4 active variants × 2 languages, i.e. 24 files); single-core artifacts were no longer published | ⚠️ A pre-2026-11-12 single-core board cannot boot the new dual-core builds — it needs a locally compiled archived single-core build. Dual-core boards need no action: flash the latest release as usual. Feature set, entity names and API are unchanged |
| 2026-11-14 | **English-first release**: pure-English firmware configs for every variant in `firmware/en/`, the Chinese originals moved to `firmware/zh/`; each release shipped 10 builds at the time (`-en` and `-zh` per version, since reduced to 8 and then 6 as v2.0 became dual-core and v1.0 was archived) | ⚠️ The English build uses new ASCII entity names (`Fan 1`, `Temp A`, `Uptime` …), so its `entity_id`s differ from the old Chinese ones; pick `-en` (primary/recommended) or `-zh`, and see the migration note below if you switch |
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
| 2026-11-15 | Wiki updated for the v1.0 archive: the English and Chinese pages now list three active v2.0 builds, six release artifacts and the `firmware/*/archive/v1.0/` paths. |
| 2026-11-14 | Wiki updated for the dual-core change: the English pages now document the active dual-core paths, the archived single-core builds, the 8-artifact release set and the 8-entry CI matrix; a Tindie purchase link was added near the top of `readme.md`. |
| 2026-11-14 | English promoted to the **primary repository language** (`readme.md`; the Chinese README became `README_ZH.md`). The English wiki was rewritten for the English firmware entity names, the `firmware/en/` + `firmware/zh/` layout and the 10-build release pipeline of the time, and the Chinese wiki was updated in parallel for the same layout. |
| 2026-11-09 | Added a bilingual Chinese/English Wiki (`docs/wiki/`, 13 pages × 2 languages); added a documentation index to the README; provided `scripts/sync-wiki.ps1` / `scripts/sync-wiki.sh` for one-command publishing to the GitHub Wiki. |

## Upgrade notes

### Upgrading from "no MAC suffix" firmware to the current version

1. In HA, **delete** the old ESPHome entry first (do not use "migrate", or it will fight with the new device);
2. Flash the new firmware over OTA or USB;
3. Add the device again; its name now carries the MAC suffix;
4. Anywhere a dashboard/automation references the old `entity_id` must be pointed at the new entity (you can first use "Developer Tools → Entities" to search for and confirm the new ID).

### Upgrading from `v1.0` to `v2.0`

- The hardware differs: the v1.0 board has no 1-Wire or radar interface, so after flashing v2.0 firmware the temperature/radar entities will always be `unknown` (the features are unavailable, but fan control is unaffected);
- Conversely, flashing an archived v1.0 single-core build on a v2.0 board only removes the extended features; fan control works normally. (On a dual-core board prefer the active `v1.0-dual-core` build.)

### Older single-core boards (shipped before 2026-11-12)

- Single-core builds are **archived**, not released: `firmware/en/archive/v1.0/single-core/config.yaml` and `firmware/en/archive/v2.0/single-core/{basic,ds18b20,ds18b20-radar}/config.yaml` (Chinese twins under `firmware/zh/archive/`);
- Compile the matching one locally (`esphome compile <config>`) and flash it over USB — a single-core board cannot boot the dual-core builds that Releases now contain;
- Everything else is unchanged: same entity names, same parameters, same behaviour, only `CONFIG_FREERTOS_UNICORE: "y"` is set.

### Switching from the Chinese build to the English build (`-zh` → `-en`)

1. Note the current parameters (`T-Min` / `T-Max` / `F-Min` / `F-Max`, radar thresholds, temperature source bindings) — they live in NVS, so a normal OTA keeps the values, but the entity names around them change;
2. In HA, **delete** the old ESPHome entry (its entities carry the Chinese names);
3. Flash the matching `-en` build over OTA or USB;
4. Add the device again. The English entities are named `Fan 1` … `Fan 4`, `Fan 1 RPM` … `Fan 4 RPM`, `Temp A` … `Temp D`, `Uptime`, `Wi-Fi Signal`, `IP Address`, `Wi-Fi SSID`, `ESPHome Version`, and (radar build) `Radar Target Detected` / `Radar Distance` / `Radar Min Distance` / `Radar Max Distance`;
5. Update dashboards, scripts and ESPHome `rest_command` URLs (`/fan/Fan%201` instead of a percent-encoded Chinese path).

The reverse direction (`-en` → `-zh`) is symmetric. Do not flash a different language edition just to "upgrade" unless you intend to migrate the entity IDs.

### About "reflashing the same version"

The Release tag is the build date, and triggering CI several times on the same day updates the same Release. If you need a traceable version, record the tag you downloaded and the `ESPHome Version` diagnostic entity.

## Compatibility matrix

| Firmware | v1.0 hardware | v2.0 hardware |
|:-----|:---------:|:---------:|
| v1.0 dual-core (active) | ⚠️ dual-core boards only | ⚠️ dual-core boards only |
| v2.0 Basic (active, dual-core) | ✅ (no extended features) | ✅ |
| v2.0 DS18B20 (active, dual-core) | ⚠️ runs, but no temperature interface | ✅ |
| v2.0 DS18B20 + radar (active, dual-core) | ⚠️ runs, but no radar interface | ✅ |
| v1.0 single-core (archived) | ✅ single-core boards | ✅ (single-core builds also run on dual-core chips) |
| v2.0 single-core (archived) | ✅ single-core boards | ✅ (same, one core idle) |

> Within a column, "✅" means full functionality and "⚠️" means it runs but lacks the corresponding hardware interface. All **active** builds are dual-core and need a dual-core board; an archived single-core build still runs on a dual-core chip, it just leaves one core idle.
>
> The matrix applies to both language editions: `-en` and `-zh` builds of one version are functionally identical and differ only in entity names.
