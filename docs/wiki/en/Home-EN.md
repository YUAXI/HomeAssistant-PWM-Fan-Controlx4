# Home · HomeAssistant-PWM-Fan-Controlx4

**English** · [中文](Home)

> An ESPHome-based 4-channel PWM fan controller: 4 independent fan channels with per-channel speed control and per-channel RPM feedback, optional DS18B20 temperature closed-loop control, optional LD2402G mmWave human presence detection, plus Home Assistant integration, a web control panel and an HTTP REST API.

![PCB photo](https://raw.githubusercontent.com/YUAXI/HomeAssistant-PWM-Fan-Controlx4/master/docs/images/hardware/pcb.jpg)

## What this is

| Item | Description |
|:-----|:-----|
| Main controller | ESP32-WROOM-32-N4 (ESP-IDF framework, Wi-Fi + BLE) |
| Fan channels | 4, independent PWM (25 kHz) + independent power switch + independent RPM input |
| Speed range | 1%–100% (`speed_count: 100`), supports stopping a fan by cutting its power completely |
| Power supply | DC 12V / 2A or more (recommended); Type-C 5V only for flashing and debugging |
| Control entry points | Home Assistant (ESPHome integration), browser web panel, HTTP REST API |
| Expansion | DS18B20 1-Wire temperature bus (up to 4), LD2402G 24 GHz radar, BLE Proxy |
| Local closed loop | The v2.0 DS18B20 firmware has a built-in temperature-control algorithm, so it runs autonomously after a power cut or without network access |

## Wiki navigation

| Page | Contents |
|:-----|:-----|
| [Quick start](Getting-Started-EN) | Unboxing check, power, first-time Wi-Fi setup, firmware flashing, Home Assistant onboarding |
| [Firmware versions](Firmware-EN) | The 4 active (dual-core) firmwares plus the archived single-core builds, how to choose, release artifacts, custom builds, multi-device naming |
| [Entity reference](Entities-EN) | Complete entity list (fan / RPM / temperature / parameters / diagnostics) with defaults and ranges |
| [Temperature control](Temperature-Control-EN) | DS18B20 wiring, 1-Wire index, linear speed algorithm, parameter tuning, abnormal behaviour |
| [mmWave radar](Radar-EN) | LD2402G wiring and serial protocol, anti-interference algorithm, distance-threshold tuning, automation examples |
| [HTTP API](HTTP-API-EN) | Complete REST endpoint set, ASCII entity names with `%20` for spaces, curl / Python / PowerShell examples, SSE event stream |
| [Home Assistant](Home-Assistant-EN) | Adding the integration, entity polish, dashboard cards, automation templates (temperature control / silent mode / alerts) |
| [Hardware](Hardware-EN) | Full GPIO table, power tree, key components, connector silkscreen, mechanical parts and assembly notes |
| [Troubleshooting](Troubleshooting-EN) | Symptom-based diagnosis: won't boot, won't come online, fan not spinning, RPM reads 0, radar false alarms, OTA failure |
| [FAQ](FAQ-EN) | Which firmware to flash (single-core vs dual-core), how large a fan it can drive, whether it can be modified for 24V, whether it works without HA, commercial licensing |
| [Development](Development-EN) | Repository layout, changing pins / adding channels, local builds, CI and release flow, how to contribute |
| [Changelog](Changelog-EN) | Firmware and hardware version history, behaviour changes and upgrade notes |

## One-minute quick start

```text
1. Download the release firmware — every controller sold after 2026-11-12 is dual-core, so pick a v2.0 variant (the -en build is recommended; -zh only if you need the Chinese entity names). Only the archived v1.0 line or a pre-2026-11-12 single-core board needs an archived build, compiled locally
2. Connect Type-C to your computer and flash the .factory.bin with ESPHome Web or esptool
3. Join the ESP32-Fan-22810 hotspot from your phone → open http://192.168.4.1 to configure Wi-Fi
4. Open http://<device IP> in a browser to control it; in HA add the ESPHome integration and enter the API encryption key
```

API encryption key (the same for every firmware):

```text
LqGIGJ3qyRc+6X6hsMe5vAms+Jyh2lOMh1FQu8yyuzk=
```

## Version cheat sheet

| Firmware | Processor | Temperature | Radar | Config file (English) |
|:-----|:------:|:----:|:----:|:---------|
| v2.0 Basic | Dual-core | - | - | `firmware/en/v2.0/dual-core/basic/config.yaml` |
| v2.0 DS18B20 | Dual-core | ✅ | - | `firmware/en/v2.0/dual-core/ds18b20/config.yaml` |
| v2.0 DS18B20 + radar | Dual-core | ✅ | ✅ | `firmware/en/v2.0/dual-core/ds18b20-radar/config.yaml` |

Every version is built in two languages: `-en` (English entity names, **primary / recommended**) and `-zh` (keeps the original Chinese entity names). The Chinese configs live under `firmware/zh/` with the same subdirectories. See [Firmware versions](Firmware-EN#languages).

> **Since 2026-11-12 every controller sold is dual-core**, so all three rows above are active dual-core builds. The **entire v1.0 line** and the older single-core design are archived under `firmware/en/archive/` (`v1.0/{dual-core,single-core}`, `v2.0/single-core/{basic,ds18b20,ds18b20-radar}`); they are no longer in Releases and must be compiled locally — see [Archived builds](Firmware-EN#archived-builds). v1.0 boards cannot boot the v2.0 firmware line in general, so use the archived v1.0 build on those.

## Key parameters

| Parameter | Value |
|:-----|:---|
| Device node name | `esp32pwm22810-<last 3 bytes of MAC>` (e.g. `esp32pwm22810-a1b2c3`) |
| HA device name | `ESP32 PWM 22810 <last 3 bytes of MAC>` |
| Hotspot SSID | `ESP32-Fan-22810` (no password, `192.168.4.1`) |
| Web panel | `http://<device IP>/` (port 80, no login) |
| mDNS | `http://esp32pwm22810-xxxxxx.local/` |
| OTA password | `4283bb50a8cd66774ce91d2c9d412cf2` |
| PWM carrier | 25 kHz |

## Related links

- [GitHub Releases (pre-built firmware)](https://github.com/YUAXI/HomeAssistant-PWM-Fan-Controlx4/releases)
- [English README](https://github.com/YUAXI/HomeAssistant-PWM-Fan-Controlx4/blob/master/readme.md) · [Chinese README](https://github.com/YUAXI/HomeAssistant-PWM-Fan-Controlx4/blob/master/README_ZH.md)
- [ESPHome documentation](https://esphome.io/)
- [Home Assistant ESPHome integration](https://www.home-assistant.io/integrations/esphome/)

![Home Assistant control interface](https://raw.githubusercontent.com/YUAXI/HomeAssistant-PWM-Fan-Controlx4/master/docs/images/screenshots/ha01.png)
