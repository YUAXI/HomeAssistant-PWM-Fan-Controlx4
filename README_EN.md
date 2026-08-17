# HomeAssistant-PWM-Fan-Controlx4

<p align="center"><a href="README_EN.md">English</a> · <a href="readme.md">中文</a></p>

An ESPHome-based 4-channel PWM fan controller with Home Assistant integration, a Web control panel, and an HTTP REST API. Each fan can be controlled and monitored independently. The v2.0 firmware also supports DS18B20 temperature control and LD2402G mmWave radar expansion.

## 1. Firmware Versions and Downloads

### 1.1 Check the Hardware First

Make sure the firmware matches the controller hardware before flashing:

> **Finished devices usually use a single-core design. They can only run `v1.0 Single-Core` or any `v2.0` firmware. Do not flash `v1.0 Dual-Core` firmware to a single-core device, or it will fail to boot.**

### 1.2 Firmware Selection

| Firmware | CPU | Main Features | Recommended Use |
|:---------|:---:|:--------------|:----------------|
| **v1.0 Dual-Core** | Dual-core | 4-channel fan control, RPM display, Web UI, HTTP API, diagnostics, BLE Proxy | Confirmed dual-core hardware requiring higher performance |
| **v1.0 Single-Core** | Single-core | 4-channel fan control, RPM display, Web UI, HTTP API, diagnostics, BLE Proxy | v1.0 single-core hardware using HA automation for temperature control |
| **v2.0 Basic** | Single-core | Basic 4-channel fan control, RPM display, Web UI, HTTP API, diagnostics, BLE Proxy | v2.0 hardware without local temperature or radar control |
| **v2.0 DS18B20** | Single-core | v2.0 Basic features + up to 4 DS18B20 sensors + local automatic speed control | Standalone cooling for servers, racks, and NAS devices |
| **v2.0 DS18B20 + Radar** | Single-core | DS18B20 features + LD2402G 24GHz mmWave presence detection | Smart home scenarios requiring presence-based fan automation |

All firmware variants support:

- Independent PWM control of 4 fans from 1-100%, including complete power shutdown.
- RPM readings for all 4 fans.
- Home Assistant ESPHome integration, a Web control panel, and an HTTP REST API.
- Diagnostic entities for uptime, Wi-Fi signal, IP address, SSID, and ESPHome version.
- BLE Proxy for extending Home Assistant Bluetooth coverage.

### 1.3 Feature Comparison

| Feature | v1.0 Dual-Core | v1.0 Single-Core | v2.0 Basic | v2.0 DS18B20 | v2.0 + Radar |
|:--------|:--------------:|:----------------:|:----------:|:------------:|:------------:|
| 4-channel PWM fan control | ✅ | ✅ | ✅ | ✅ | ✅ |
| Complete power shutdown | ✅ | ✅ | ✅ | ✅ | ✅ |
| Real-time RPM display | ✅ | ✅ | ✅ | ✅ | ✅ |
| Web UI / HTTP API | ✅ | ✅ | ✅ | ✅ | ✅ |
| Diagnostic entities | ✅ | ✅ | ✅ | ✅ | ✅ |
| BLE Proxy | ✅ | ✅ | ✅ | ✅ | ✅ |
| DS18B20 temperature control | - | - | - | ✅ | ✅ |
| LD2402G mmWave radar | - | - | - | - | ✅ |

### 1.4 Download Pre-built Firmware

Firmware is compiled and published automatically by GitHub Actions:

[Go to GitHub Releases](https://github.com/YUAXI/HomeAssistant-PWM-Fan-Controlx4/releases)

Each firmware variant includes these 3 file types:

| File Suffix | Purpose |
|:------------|:--------|
| `.firmware.bin` | Standard firmware for regular flashing |
| `.firmware.factory.bin` | Factory firmware for a complete factory reset |
| `.firmware.ota.bin` | OTA upgrade firmware for networked devices |

Release names and their corresponding configuration files:

| Release Name | Configuration File |
|:-------------|:-------------------|
| `v1.0-dual-core` | `firmware/v1.0/dual-core/config.yaml` |
| `v1.0-single-core` | `firmware/v1.0/single-core/config.yaml` |
| `v2.0-basic` | `firmware/v2.0/single-core/basic/config.yaml` |
| `v2.0-ds18b20` | `firmware/v2.0/single-core/ds18b20/config.yaml` |
| `v2.0-ds18b20-radar` | `firmware/v2.0/single-core/ds18b20-radar/config.yaml` |

### 1.5 Custom Compilation

To change Wi-Fi, entity names, or other ESPHome settings, edit the corresponding `config.yaml` above and compile or flash it with ESPHome. All configurations use the ESP32 DevKit board and the ESP-IDF framework; v1.0 Single-Core and all v2.0 firmware explicitly enable single-core operation.

## 2. Quick Start

### 2.1 Power Supply

| Power Method | Interface | Voltage | Description |
|:-------------|:----------|:--------|:------------|
| **DC jack (recommended)** | DC barrel jack | 12V / 2A or higher | Normal operation; powers the fans and ESP32 |
| Type-C port | USB-C | 5V | Flashing and debugging only; cannot drive the fans normally |

### 2.2 First-time Wi-Fi Setup

After startup, the device creates an open Wi-Fi hotspot named `ESP32-Fan-22810`:

1. Connect to `ESP32-Fan-22810` with a phone or computer.
2. Open `http://192.168.4.1` or `http://esp32pwm22810.local` in a browser.
3. Select the target Wi-Fi network and enter its password.
4. The device connects and reboots automatically.

To skip first-time setup, set `wifi.ssid` and `wifi.password` in the configuration file before flashing.

### 2.3 Flash the Firmware

Connect the device to a computer with a Type-C cable, select the firmware matching the hardware, and flash it with the ESPHome flashing tool or `esptool`. Once the device is online, use `.firmware.ota.bin` for remote updates.

### 2.4 Add the Device to Home Assistant

Make sure the Home Assistant ESPHome integration is installed:

1. Open **Settings → Devices & Services → Add Integration** and search for **ESPHome**.
2. Select the discovered device `ESP32 PWM 22810`, or enter its IP address manually.
3. Enter the API encryption key from the configuration files:

   ```text
   LqGIGJ3qyRc+6X6hsMe5vAms+Jyh2lOMh1FQu8yyuzk=
   ```

The following entities are normally created:

| Entity Type | Count | Description |
|:------------|:-----:|:------------|
| Fan | 4 | Independent on/off and 1-100% speed control |
| RPM sensor | 4 | Unit: RPM |
| Temperature sensor | 4 | Only in v2.0 DS18B20 and Radar firmware; Temperature A/B/C/D |
| BLE Proxy | 1 | BLE Proxy node |
| Diagnostic entities | Several | Uptime, Wi-Fi signal, IP, SSID, ESPHome version, etc. |

### 2.5 Web Control Panel

Open `http://device-ip` in a browser to access the Web control panel without Home Assistant. The panel shows all 4 fan states, allows independent speed adjustment, and displays device information.

## 3. v2.0 Temperature and Radar Features

### 3.1 DS18B20 Wiring

Connect DS18B20 sensors to the onboard **GPIO14** 3-pin header using the 1-Wire bus:

| DS18B20 Pin | Connection |
|:-----------:|:-----------|
| VCC | 3.3V or 5V |
| GND | GND |
| DATA | GPIO14 |

The board includes a pull-up resistor. Up to 4 DS18B20 sensors can be connected in parallel to GPIO14 and are named **Temperature A, Temperature B, Temperature C, and Temperature D** according to their bus index.

### 3.2 Local Temperature Control

This section applies to `v2.0-ds18b20` and `v2.0-ds18b20-radar`. In the Home Assistant device page for **ESP32 PWM 22810**, configure a temperature source and parameters for each fan:

| Parameter | Description | Default |
|:----------|:------------|:-------:|
| Temperature source `F-Src` | Select unbound or Temperature A/B/C/D | Fans 1-4 use A-D respectively |
| Trigger temperature `T-Min` | At or below this temperature, power the fan off | 30°C |
| Full-speed temperature `T-Max` | At or above this temperature, use the maximum speed | 50°C |
| Minimum speed `F-Min` | Minimum speed in the linear control range | 0% |
| Maximum speed `F-Max` | Maximum speed in the linear control range | 100% |

Control logic:

```text
Temperature ≤ T-Min                   → Completely power off the fan
T-Min < Temperature < T-Max           → Linear proportional speed control
Temperature ≥ T-Max                   → Run at F-Max
Temperature read failure              → Keep the current speed and state
```

These parameters persist across power cycles. A fan with no bound temperature source is not controlled by the local temperature logic and can still be controlled manually through Home Assistant, the Web UI, or the HTTP API.

### 3.3 LD2402G Radar Interface

The radar UART is enabled only by `v2.0-ds18b20-radar`:

| Radar Pin | Controller Pin |
|:----------|:---------------|
| TX | GPIO4 (UART RX) |
| RX | GPIO5 (UART TX) |
| Power / Ground | 5V / GND on the v2.0 developer header |

The UART speed is `115200`. The radar firmware provides target presence and target distance entities, plus configurable minimum and maximum distance filters. The default range is `0.10-1.5 m`. Use Home Assistant automations to link radar presence with fan and temperature control.

## 4. Home Assistant Temperature Automation

The v2.0 DS18B20 firmware already supports local temperature control. The following method works with all firmware versions and is especially useful for v1.0 or for external temperature sources such as CPU and ambient temperature sensors exposed by Home Assistant.

### 4.1 Configuration Steps

1. Open Home Assistant → **Automations & Scenes → Create Automation**.
2. Select **More → Edit in YAML** in the top-right corner.
3. Paste the template below.
4. Replace the temperature sensor and fan entity IDs, then save.

### 4.2 YAML Template

```yaml
alias: "Smart Fan Linear Speed Control"
description: "Linearly controls fan PWM duty cycle based on temperature sensor readings"
mode: restart

trigger:
  - platform: state
    entity_id: sensor.nas_temperature_x86_pkg_temp  # Change this

condition:
  - condition: template
    value_template: "{{ is_number(states('sensor.nas_temperature_x86_pkg_temp')) }}"  # Change this

action:
  - service: fan.set_percentage
    target:
      entity_id: fan.fan_1  # Change this
    data:
      percentage: >
        {% set current_temp = states('sensor.nas_temperature_x86_pkg_temp') | float(0) %}  {# Change this #}
        {% set t_min = 30 %}
        {% set t_max = 50 %}
        {% set f_min = 0 %}
        {% set f_max = 100 %}
        {% if current_temp <= t_min %}
          {{ f_min }}
        {% elif current_temp >= t_max %}
          {{ f_max }}
        {% else %}
          {% set result = ((current_temp - t_min) * (f_max - f_min) / (t_max - t_min) + f_min) %}
          {{ result | round(0) | int }}
        {% endif %}
```

![Temperature vs. Speed](./docs/images/diagrams/speed-chart.png)

Common temperature source examples:

| Temperature Source | Integration | Example Entity ID |
|:-------------------|:------------|:------------------|
| PC / server CPU | Glances | `sensor.nas_temperature_x86_pkg_temp` |
| Temperature / humidity sensor | Zigbee2MQTT / ZHA | `sensor.temperature_humidity_sensor_temperature` |
| Air conditioner / heater | Smart AC integration | `climate.living_air_conditioner` |
| Synology NAS | Synology DSM integration | `sensor.synology_disk_1_temperature` |
| Other ESPHome device | ESPHome integration | Use the actual entity ID |

## 5. HTTP REST API

The built-in Web Server accepts LAN HTTP requests for fan control and sensor readings. Use **POST** for control commands and **GET** for status queries. Entity names contain Chinese characters, so URL paths must be UTF-8 encoded.

### 5.1 Entity and Path Examples

ESPHome generates entity IDs from the configured `name`. The following examples show Fan 1:

| Entity Name | entity_id | URL Path |
|:------------|:----------|:---------|
| Fan 1 | `fan.风扇_1` | `/fan/%E9%A3%8E%E6%89%87_1` |
| Fan 1 RPM | `sensor.风扇_1_转速` | `/sensor/%E9%A3%8E%E6%89%87_1_%E8%BD%AC%E9%80%9F` |

Replace the entity name in the path for other fans. Alternatively, use Home Assistant's `fan.set_percentage` service to avoid handling Chinese URL encoding manually.

### 5.2 Python Example

```python
import requests
from urllib.parse import quote

base = "http://10.0.20.83"  # Replace with the device IP

# Turn on Fan 2 and set it to 50%
requests.post(f"{base}/fan/{quote('风扇 2')}/turn_on", params={"speed_level": 50})

# Turn off Fan 2
requests.post(f"{base}/fan/{quote('风扇 2')}/turn_off")

# Read the RPM of Fan 1
response = requests.get(f"{base}/sensor/{quote('风扇 1 转速')}")
if response.status_code == 200:
    print("Current RPM:", response.json()["value"])
```

## 6. Hardware Files and Interfaces

### 6.1 Hardware Files

v2.0 is the recommended hardware version:

| Type | v2.0 File | v1.0 File |
|:-----|:----------|:----------|
| PCB Gerber | [gerber.zip](./hardware/v2.0/pcb/gerber.zip) | [gerber.zip](./hardware/v1.0/pcb/gerber.zip) |
| BOM | [bom.xlsx](./hardware/v2.0/pcb/bom.xlsx) | [bom.xlsx](./hardware/v1.0/pcb/bom.xlsx) |
| LCSC EDA project | [project.epro2](./hardware/v2.0/pcb/project.epro2) | [project.epro2](./hardware/v1.0/pcb/project.epro2) |
| Enclosure body | [case.STEP](./hardware/v2.0/3d-models/print/case.STEP) | [case.step](./hardware/v1.0/3d-models/print/case.step) |
| Top cover | [top-cover.STEP](./hardware/v2.0/3d-models/print/top-cover.STEP) | [top-cover.step](./hardware/v1.0/3d-models/print/top-cover.step) |

### 6.2 Fan Pin Mapping

| Fan | PWM Output | Tachometer Input | Power Management |
|:---:|:----------:|:----------------:|:----------------:|
| Fan1 | GPIO16 | GPIO32 | GPIO21 |
| Fan2 | GPIO17 | GPIO33 | GPIO22 |
| Fan3 | GPIO18 | GPIO25 | GPIO23 |
| Fan4 | GPIO19 | GPIO26 | GPIO13 |

Additional v2.0 interfaces:

| Interface | Description |
|:----------|:------------|
| GPIO14 (3-pin header) | DS18B20 1-Wire temperature bus |
| 4-pin developer header (5V / GND / GPIO5 / GPIO4) | Expansion for LD2402G radar, RS485, and other peripherals |

### 6.3 Hardware Design Highlights

- **Fan power control**: `TPS22810DBVR` directly cuts fan power for complete shutdown.
- **Power scheme**: 12V → 5V (`TPS5430DDAR` DC-DC) → 3.3V (`AMS1117-3.3`).
- **USB-to-Serial**: Onboard `CH340C` for flashing and debugging over Type-C.

## 7. Project Gallery

<div style="text-align: center;">
  <table>
    <tr>
      <td width="25%" style="padding: 10px;"><img src="./docs/images/hardware/pcb.jpg" width="450" alt="PCB board"/></td>
      <td width="25%" style="padding: 10px;"><img src="./docs/images/hardware/physical.jpg" width="450" alt="Test setup"/></td>
      <td width="25%" style="padding: 10px;"><img src="./docs/images/screenshots/ha01.png" width="250" alt="Home Assistant control interface"/></td>
      <td width="25%" style="padding: 10px;"><img src="./docs/images/screenshots/ha02.png" width="250" alt="Home Assistant device diagnostics"/></td>
    </tr>
  </table>
</div>

## 8. Changelog

| Date | Changes |
|:-----|:--------|
| 2026-08-16 | Fans are powered off when automatic control temperature is at or below `T-Min`, and restart when the temperature rises. |
| 2026-07-10 | On DS18B20 read failure, keep the current fan speed and remove forced full-speed protection. |
| 2026-07-01 | Added BLE Proxy to all variants; enabled CI firmware builds and Release publishing; removed pre-built firmware from the repository. |
| v2.0 | Added DS18B20 temperature control, the mmWave radar firmware, and the v2.0 hardware design. |
| v1.0 | Added the Web UI, HTTP REST API, and diagnostic entities. |

## 9. Support and License

Community group QR codes are no longer maintained.

<div style="text-align: center;">
  <table>
    <tr>
      <td width="50%" style="padding: 10px;"><img src="./docs/images/donations/wechat.jpg" width="220" alt="WeChat donation"/><p><small>WeChat Pay</small></p></td>
      <td width="50%" style="padding: 10px;"><img src="./docs/images/donations/alipay.jpg" width="220" alt="Alipay donation"/><p><small>Alipay</small></p></td>
    </tr>
  </table>
</div>

This project is licensed under the [MIT License](./LICENSE).
