# HomeAssistant-PWM-Fan-Controlx4

<p align="center"><a href="README_EN.md">English</a> · <a href="readme.md">中文</a></p>

## Project Overview

HomeAssistant-PWM-Fan-Controlx4 is an ESPHome-based PWM fan controller project. It integrates with Home Assistant to provide independent speed control and intelligent联动 (linked) control for 4 fan channels.

**Key Features:**

- Home Assistant control via ESPHome integration
- 4-channel independent PWM speed control with real-time RPM display (1-100%), supporting **full fan shutdown**
- Web UI / HTTP REST API direct control
- Built-in diagnostic entities (uptime, Wi-Fi signal strength, IP address, firmware version, etc.)
- v2.0 provides DS18B20 temperature sensor interface, supporting **local temperature-driven speed regulation** (also configurable via HA automation)
- v2.0 Radar version supports 24GHz mmWave human presence detection
- All versions support **BLE Proxy**, extending Home Assistant Bluetooth coverage

## Changelog

| Date | Changes |
|:-----|:--------|
| 2026-07-10 | On DS18B20 temperature read failure, maintain current fan speed instead of full-speed protection |
| 2026-07-01 | BLE Proxy added across all versions; CI auto-build and Release publishing; pre-built firmware removed from repo; README restructured |
| v2.0 | Built-in DS18B20 temperature control, mmWave radar variant, v2.0 hardware design |
| v1.0 | Web UI control, HTTP REST API, diagnostic entities |

## Project Gallery

<div style="text-align: center;">
  <table>
    <tr>
      <td width="25%" style="padding: 10px;">
        <img src="./docs/images/hardware/pcb.jpg" width="450" alt="PCB Board"/>
      </td>
      <td width="25%" style="padding: 10px;">
        <img src="./docs/images/hardware/physical.jpg" width="450" alt="Test Setup"/>
      </td>
      <td width="25%" style="padding: 10px;">
        <img src="./docs/images/screenshots/ha01.png" width="250" alt="Home Assistant Control UI"/>
      </td>
      <td width="25%" style="padding: 10px;">
        <img src="./docs/images/screenshots/ha02.png" width="250" alt="Home Assistant Device Diagnostics"/>
      </td>
    </tr>
  </table>
</div>

---

## Hardware Files

### v2.0 Hardware (Recommended)

| Type | File | Description |
|:-----|:-----|:------------|
| PCB Gerber | [gerber.zip](./hardware/v2.0/pcb/gerber.zip) | Ready for PCB fabrication |
| BOM | [bom.xlsx](./hardware/v2.0/pcb/bom.xlsx) | Bill of Materials |
| EDA Project | [project.epro2](./hardware/v2.0/pcb/project.epro2) | LCSC EDA Professional Edition |
| Enclosure Body | [case.STEP](./hardware/v2.0/3d-models/print/case.STEP) | STEP format 3D model |
| Top Cover | [top-cover.STEP](./hardware/v2.0/3d-models/print/top-cover.STEP) | STEP format 3D model |

### v1.0 Hardware

| Type | File |
|:-----|:-----|
| PCB Gerber | [gerber.zip](./hardware/v1.0/pcb/gerber.zip) |
| BOM | [bom.xlsx](./hardware/v1.0/pcb/bom.xlsx) |
| EDA Project | [project.epro2](./hardware/v1.0/pcb/project.epro2) |
| Enclosure Body | [case.step](./hardware/v1.0/3d-models/print/case.step) |
| Top Cover | [top-cover.step](./hardware/v1.0/3d-models/print/top-cover.step) |

---

## Hardware Design

- **Fan power control**: Uses `TPS22810DBVR` to completely cut off fan power, achieving **full shutdown** — solving the issue where ordinary PWM controllers cannot fully stop fans
- **Power scheme**: 12V → 5V (`TPS5430DDAR` DC-DC) → 3.3V (`AMS1117-3.3`), high efficiency, low ripple
- **USB-to-Serial**: Onboard `CH340C`, flashing via Type-C connection

## IO Pin Mapping

| Fan | PWM Output | Tach Input | Power Management |
|:---:|:----------:|:----------:|:----------------:|
| Fan1 | GPIO16     | GPIO32     | GPIO21           |
| Fan2 | GPIO17     | GPIO33     | GPIO22           |
| Fan3 | GPIO18     | GPIO25     | GPIO23           |
| Fan4 | GPIO19     | GPIO26     | GPIO13           |

**v2.0 Additional Interfaces**:

| Interface | Description |
|:----------|:------------|
| GPIO14 (3-pin header) | DS18B20 temperature sensor 1-Wire bus |
| 4-pin Developer Header (5V / GND / GPIO5 / GPIO4) | General-purpose expansion interface, compatible with LD2402G radar, RS485 modules, etc. The Radar firmware variant uses this interface with LD2402G as a reference implementation |

---

## Firmware Versions

> ⚠️ If you purchased a finished device, the MCU uses a **single-core design** — **only flash v1.0 single-core or any v2.0 firmware**. Dual-core firmware will inevitably fail to boot.

### Version Overview

| Version | Key Feature | Use Case |
|:--------|:------------|:---------|
| **v1.0 Dual-Core** | Basic 4-channel fan control, dual-core operation | For users with existing HA automation needing higher performance |
| **v1.0 Single-Core** | Basic 4-channel fan control, single-core low power | For users with existing HA automation, power-sensitive |
| **v2.0 Basic** | Simple fan control, single-core | Entry-level firmware for v2.0 hardware without temperature or radar needs |
| **v2.0 DS18B20** | Built-in DS18B20 temperature control, auto-speed without HA dependency | Server/rack/NAS cooling requiring standalone operation |
| **v2.0 DS18B20+Radar** | Above features + 24GHz mmWave human presence detection | Smart home scenarios needing presence-triggered fan control |

### Feature Comparison

| Feature | v1.0 Dual-Core | v1.0 Single-Core | v2.0 Basic | v2.0 DS18B20 | v2.0 +Radar |
|:--------|:--------------:|:----------------:|:----------:|:------------:|:-----------:|
| 4-Channel PWM Fan Control | ✅ | ✅ | ✅ | ✅ | ✅ |
| Real-time RPM Display | ✅ | ✅ | ✅ | ✅ | ✅ |
| Web UI / HTTP API | ✅ | ✅ | ✅ | ✅ | ✅ |
| Diagnostic Entities | ✅ | ✅ | ✅ | ✅ | ✅ |
| BLE Proxy | ✅ | ✅ | ✅ | ✅ | ✅ |
| DS18B20 Temperature Control | - | - | - | ✅ | ✅ |
| mmWave Radar | - | - | - | - | ✅ |
| CPU Cores | Dual-Core | Single-Core | Single-Core | Single-Core | Single-Core |

### How to Get Firmware

Firmware is automatically compiled and published by GitHub Actions — no manual packaging needed:

[→ Go to Releases](https://github.com/YUAXI/HomeAssistant-PWM-Fan-Controlx4/releases)

Each Release contains three firmware files per variant:

| Release Filename | Corresponding Version |
|:-----------------|:----------------------|
| `v1.0-dual-core.firmware.bin` | v1.0 Dual-Core |
| `v1.0-single-core.firmware.bin` | v1.0 Single-Core |
| `v2.0-basic.firmware.bin` | v2.0 Basic |
| `v2.0-ds18b20.firmware.bin` | v2.0 DS18B20 |
| `v2.0-ds18b20-radar.firmware.bin` | v2.0 DS18B20+Radar |

Each firmware variant includes 3 files:

| File Suffix | Purpose |
|:------------|:--------|
| `.firmware.bin` | Standard firmware, regular flashing |
| `.firmware.factory.bin` | Factory firmware, full factory reset |
| `.firmware.ota.bin` | OTA upgrade firmware |

**Flashing method**: Connect via Type-C to your computer, use the ESPHome flashing tool or esptool.

**Custom Compilation**: If you need to modify the configuration, use the `.yaml` files in the source code:

| Version | Config File |
|:--------|:------------|
| v1.0 Dual-Core | `firmware/v1.0/dual-core/config.yaml` |
| v1.0 Single-Core | `firmware/v1.0/single-core/config.yaml` |
| v2.0 Basic | `firmware/v2.0/single-core/basic/config.yaml` |
| v2.0 DS18B20 | `firmware/v2.0/single-core/ds18b20/config.yaml` |
| v2.0 DS18B20+Radar | `firmware/v2.0/single-core/ds18b20-radar/config.yaml` |

---

## Quick Start Guide

> **API Encryption Key**: `LqGIGJ3qyRc+6X6hsMe5vAms+Jyh2lOMh1FQu8yyuzk=`

### 1. Power Supply & Startup

| Power Method | Interface | Voltage | Description |
|:-------------|:----------|:--------|:------------|
| **DC Jack** (Recommended) | DC Barrel | 12V/2A+ | Normal operation; powers both fans and ESP32 |
| Type-C Port | USB-C | 5V | Flashing/debugging only; fans will not operate |

On power-up, the device automatically creates a Wi-Fi hotspot named `ESP32-Fan-22810` (no password). Connect with your phone or computer to begin network configuration.

### 2. Connect to Wi-Fi

1. Connect to the `ESP32-Fan-22810` hotspot
2. Open a browser and visit `http://192.168.4.1` or `http://esp32pwm22810.local`
3. In the Wi-Fi configuration wizard, select your home/office Wi-Fi and enter the password
4. The device will automatically connect and reboot

> **Tip**: Pre-configure `wifi.ssid` and `wifi.password` in `config.yaml` before flashing, and the device will auto-connect on first boot.

### 3. Add to Home Assistant

Ensure the ESPHome integration is installed, then:

1. **Settings** → **Devices & Services** → **Add Integration** → Search for **ESPHome**
2. The device named `ESP32 PWM 22810` will be auto-discovered (or enter the IP manually)
3. Enter the API key and submit

Entities auto-created after successful addition:

| Entity Type | Count | Description |
|:------------|:-----:|:------------|
| Fan | 4 | Supports on/off and 1-100% speed adjustment |
| Temperature Sensor | 4 | Temperature A/B/C/D (v2.0, requires DS18B20 connection) |
| Speed Sensor | 4 | Unit: RPM |
| BLE Proxy | 1 | BLE Proxy node |
| Diagnostic Entities | Several | Uptime, Wi-Fi signal, IP, firmware version, etc. |

### 4. Web UI Control

Browse to `http://[device-ip]` to access the Web control panel — no Home Assistant required:
- View real-time status of all 4 fans
- Independently adjust each fan speed (1-100%) via sliders
- View device runtime information

### 5. Configuring v2.0 Temperature Control (DS18B20 Variant)

> This section applies to **v2.0 DS18B20 / DS18B20+Radar** firmware. If you are not using a DS18B20 probe, you can implement temperature-linked speed control via [Home Assistant automation](#home-assistant-automation-configuration).

#### DS18B20 Wiring

The DS18B20 uses a 3-wire connection to the onboard **GPIO14** (3-pin header):

| DS18B20 Pin | Connection |
|:-----------:|:-----------|
| Red (VCC) | 3.3V or 5V |
| Black (GND) | GND |
| Yellow (DATA) | GPIO14 (onboard pull-up resistor pre-installed) |

Up to **4 DS18B20 sensors** can be paralleled on the GPIO14 bus. They are auto-detected and named **Temperature A / B / C / D**.

#### Temperature Binding Configuration

Navigate to HA → **Settings** → **Devices & Services** → **ESP32 PWM 22810**, and configure each fan's parameters:

| Parameter | Description | Default |
|:----------|:------------|:-------:|
| Trigger Temp T-Min | Below this temperature, fan runs at minimum speed | 30°C |
| Full-Speed Temp T-Max | Above this temperature, fan runs at maximum speed | 50°C |
| Min Speed F-Min | Minimum fan speed percentage | 0% |
| Max Speed F-Max | Maximum fan speed percentage | 100% |
| Temp Source Src | Temperature sensor bound to this fan | - |

**Operating Logic**:

```
Temperature ≤ Trigger Temp  →  Run at minimum speed (or stop)
Trigger Temp < Temperature < Full-Speed Temp  →  Linear proportional speed control
Temperature ≥ Full-Speed Temp  →  Run at maximum speed
```

All parameters are **persistent across power loss** — set once and done.

---

## HTTP REST API

This project includes a Web Server that allows direct fan control and sensor data retrieval via LAN HTTP requests.

> ⚠️ Control commands (turn on/off, speed adjustment) use **POST**; status retrieval uses **GET**.
> Chinese characters in URLs must be URL-encoded (space → `%20`, Chinese text → UTF-8 encoding).

### entity_id Reference

As of ESPHome 2026.6.4, `object_id` is not supported by most components; `entity_id` is auto-derived from `name`.

| Display Name | entity_id | URL Path |
|:-------------|:----------|:---------|
| 风扇 1 (Fan 1) | `fan.风扇_1` | `/fan/%E9%A3%8E%E6%89%87_1` |
| 风扇 1 转速 (Fan 1 RPM) | `sensor.风扇_1_转速` | `/sensor/%E9%A3%8E%E6%89%87_1_%E8%BD%AC%E9%80%9F` |

> **Note**: Since entity IDs contain Chinese characters, it is recommended to use Home Assistant's `fan.set_percentage` service, or use `urllib.parse.quote()` in Python for automatic encoding.

### Python Example

```python
import requests
from urllib.parse import quote

base = "http://10.0.20.83"

# Turn on Fan 2 and set speed to 50%
requests.post(f"{base}/fan/{quote('风扇 2')}/turn_on", params={"speed_level": 50})

# Turn off Fan 2
requests.post(f"{base}/fan/{quote('风扇 2')}/turn_off")

# Get current RPM of Fan 1
response = requests.get(f"{base}/sensor/{quote('风扇 1 转速')}")
if response.status_code == 200:
    print("Current RPM:", response.json()['value'])
```

---

## Home Assistant Automation Configuration

> **v2.0 users**: The DS18B20 variant has built-in local temperature control, but the following automation method is also available. This configuration applies to all versions, and is especially suitable for v1.0 users or those needing non-DS18B20 temperature sources such as CPU temperature, ambient temperature/humidity from HA.

### Configuration Steps

1. Open Home Assistant → **Automations & Scenes** → **Create Automation**
2. Click **More** (top-right) → **Edit in YAML**
3. Paste the template below, **modify the entity IDs**, and save

### YAML Template

```yaml
alias: "Smart Fan Linear Speed Control"
description: "Linearly controls fan PWM duty cycle based on temperature sensor readings"
mode: restart

trigger:
  - platform: state
    entity_id: sensor.nas_temperature_x86_pkg_temp  # 【MODIFY THIS】

condition:
  - condition: template
    value_template: "{{ is_number(states('sensor.nas_temperature_x86_pkg_temp')) }}"  # 【MODIFY THIS】

action:
  - service: fan.set_percentage
    target:
      entity_id: fan.fan_1  # 【MODIFY THIS】
    data:
      percentage: >
        {% set current_temp = states('sensor.nas_temperature_x86_pkg_temp') | float(0) %}  {# 【MODIFY THIS】 #}
        {% set t_min = 30 %}   {# Trigger temperature #}
        {% set t_max = 50 %}   {# Full-speed temperature #}
        {% set f_min = 0 %}    {# Minimum speed % #}
        {% set f_max = 100 %}  {# Maximum speed % #}
        {% if current_temp <= t_min %}
          {{ f_min }}
        {% elif current_temp >= t_max %}
          {{ f_max }}
        {% else %}
          {% set result = ((current_temp - t_min) * (f_max - f_min) / (t_max - t_min) + f_min) %}
          {{ result | round(0) | int }}
        {% endif %}
```

### Temperature vs Speed Relationship

![Temperature vs Speed Chart](./docs/images/diagrams/speed-chart.png)

### Common Temperature Sources

| Temperature Source | Integration Method | Example Entity ID |
|:------------------|:-------------------|:------------------|
| PC/Server CPU Temperature | Glances Integration | `sensor.nas_temperature_x86_pkg_temp` |
| Temperature/Humidity Sensor | Zigbee2MQTT / ZHA | `sensor.temperature_humidity_sensor_temperature` |
| AC/Heater Temperature | Smart AC Integration | `climate.living_air_conditioner` |
| Synology NAS Temperature | Synology DSM Integration | `sensor.synology_disk_1_temperature` |
| Other ESPHome Devices | ESPHome Integration | Custom |

---

## Community

**QR codes for community groups are no longer maintained.**

## Support the Project

<div style="text-align: center;">
  <table>
    <tr>
      <td width="50%" style="padding: 10px;">
        <img src="./docs/images/donations/wechat.jpg" width="220" alt="WeChat Pay"/>
        <p><small>WeChat Pay</small></p>
      </td>
      <td width="50%" style="padding: 10px;">
        <img src="./docs/images/donations/alipay.jpg" width="220" alt="Alipay"/>
        <p><small>Alipay</small></p>
      </td>
    </tr>
  </table>
</div>

## Open Source License

This project is licensed under the [MIT License](./LICENSE).
