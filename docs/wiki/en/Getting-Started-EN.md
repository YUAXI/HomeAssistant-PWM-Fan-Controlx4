# Getting Started

[← Home](Home-EN) · [中文](Getting-Started) · **English**

This page covers the whole flow from unboxing to seeing 4 fans in Home Assistant. If you already have a pre-flashed retail device, you can jump straight to [2.2 First-time Wi-Fi setup](#22-first-time-wi-fi-setup).

## 2.1 Unboxing and power

### Package contents (retail device)

| Part | Description |
|:-----|:-----|
| Controller board | v1.0 or v2.0, ESP32 module pre-installed |
| Fan connectors | 4 standard 4-pin fan headers (12V / GND / Tach / PWM) |
| DC power jack | 5.5×2.1 mm, 12V input |
| Type-C port | 5V, flashing and debugging only, **cannot drive the fans** |

### Power requirements

| Power source | Connector | Voltage | Description |
|:---------|:-----|:-----|:-----|
| **DC jack (recommended)** | DC jack | 12V / 2A or more | Normal operation, powers both the fans and the ESP32 |
| Type-C port | USB-C | 5V | Flashing and debugging only; at 5V the fans basically won't spin |

> When all 4 fans run at full load, leave headroom for the sum of the currents on the fan nameplates: 4 × 0.3A ≈ 1.2A, so a 12V / 3A supply is more stable. The onboard DC-DC converter (TPS5430) feeds the 5V rail, and 3.3V is provided by an AMS1117.

### First power-on self-check

- After power-up the fans **stay off by default**: the 4 power switches use `restore_mode: ALWAYS_OFF` and the fan entities use `restore_mode: RESTORE_DEFAULT_OFF`.
- With no Wi-Fi configured, the device brings up the `ESP32-Fan-22810` hotspot (no password).
- The ESP32 module is visible next to the silkscreen on the board, and the CH340C USB-serial chip sits next to the Type-C port.

## 2.2 First-time Wi-Fi setup

1. Connect a phone or computer to the password-free hotspot **`ESP32-Fan-22810`**.
2. Browse to **`http://192.168.4.1`** (recommended; the captive portal setup page pops up automatically).
3. Select the target Wi-Fi network, enter its password and submit.
4. The device saves the credentials, reboots and connects.

Additional notes:

| Scenario | What to do |
|:-----|:-----|
| Forgot the device IP | Check the router's DHCP list, or visit `http://esp32pwm22810-xxxxxx.local/` (`xxxxxx` is the last 3 bytes of the MAC, all lowercase) |
| Want to skip provisioning | Pre-set `wifi.ssid` / `wifi.password` in the config before flashing (see [Firmware versions](Firmware-EN#custom-compilation)) |
| Changing Wi-Fi | If the device cannot reach the old network after a reboot it falls back to hotspot mode automatically; you can also re-provision via the ESPHome "Configure" dialog in HA |

## 2.3 Flashing the firmware

### Choose the firmware first

| Your hardware | Recommended firmware |
|:---------|:---------|
| Not sure whether single-core or dual-core | **Any v2.0 firmware** or **v1.0 single-core** (single-core firmware also runs on dual-core chips) |
| Confirmed dual-core | v1.0 dual-core, or v2.0 |
| Need local temperature control | v2.0 DS18B20 |
| Need human presence detection | v2.0 DS18B20 + radar |

For the full comparison see [Firmware versions](Firmware-EN).

### Option A: ESPHome Web (simplest, no toolchain needed)

1. Connect Type-C to your computer and open <https://web.esphome.io> (Chrome / Edge).
2. Click **Connect** and pick the serial port that appears (on Windows it looks like `COM5`, chip is `CH340`).
3. Choose **Install** → upload the **`.firmware.factory.bin`** you downloaded (it contains the bootloader, so the factory build is mandatory).
4. Wait for the write to finish; the device reboots automatically.

### Option B: esptool on the command line (optional, handy for batches and troubleshooting)

```bash
# install
pip install esptool

# first flash: write the factory image at 0x0
esptool.py --chip esp32 --port COM5 --baud 460800 \
  write_flash 0x0 v2.0-basic.firmware.factory.bin

# if you only have the app image (.firmware.bin), the offset is 0x10000
esptool.py --chip esp32 --port COM5 --baud 460800 \
  write_flash 0x10000 v2.0-basic.firmware.bin

# cannot enter download mode: hold BOOT (IO0), tap RST, then release BOOT
```

On Linux / macOS replace `COM5` with `/dev/ttyUSB0` or `/dev/cu.usbserial-*`; if the download fails, drop the baud rate to `115200`.

### Option C: Build and flash with ESPHome (for custom configs)

```bash
pip install esphome
esphome compile firmware/v2.0/single-core/ds18b20/config.yaml
esphome upload  firmware/v2.0/single-core/ds18b20/config.yaml   # pick the serial port when prompted
```

### Option D: OTA-update a device that is already on the network

```bash
# option 1: point the ESPHome CLI at the device address
esphome upload firmware/v2.0/single-core/ds18b20/config.yaml --device 192.168.1.50

# option 2: click INSTALL → Wirelessly in the ESPHome Dashboard
# option 3: HA → ESPHome integration → device page → three dots → Update (when offered)
```

For the OTA target use the device's own IP or `<node name>.local`; the OTA password is `4283bb50a8cd66774ce91d2c9d412cf2`.

> ⚠️ Losing power during an OTA corrupts the application partition and you have to go back to flashing over USB. Before upgrading, make sure the firmware matches the hardware revision.

## 2.4 Adding it to Home Assistant

1. **Settings → Devices & Services → Add Integration**, search for **ESPHome**.
2. Select the auto-discovered `ESP32 PWM 22810 xxxxxx`, or enter the device IP manually.
3. Enter the API encryption key and submit:

   ```text
   LqGIGJ3qyRc+6X6hsMe5vAms+Jyh2lOMh1FQu8yyuzk=
   ```

4. A retail device normally exposes the entities in the table below (full list in [Entity reference](Entities-EN)).

| Entity type | Count | Description |
|:---------|:----:|:-----|
| Fan | 4 | Independent on/off + 1–100% speed control |
| RPM sensor | 4 | Unit RPM, refreshed every 4 s |
| Temperature sensor | 4 | DS18B20 / radar firmware only, named 温度 A–D |
| Radar entities | 2 | Radar firmware only: presence state + target distance |
| Bluetooth proxy | 1 | Extends HA Bluetooth coverage |
| Diagnostic entities | 5 | Uptime, Wi-Fi signal, IP, SSID, ESPHome version |

If the device keeps showing up as "Discovered" but adding it fails, the IP is usually wrong or a firewall is blocking it: first open `http://<device IP>/` in a browser to confirm it is reachable.

## 2.5 Web control panel

Just open `http://<device IP>/` in a browser, no Home Assistant required:

- View the status and RPM of all 4 fan channels;
- Drag the sliders to adjust each fan speed independently;
- View the temperature-control parameters (`T-Min` / `T-Max` / `F-Min` / `F-Max`) and the radar thresholds;
- The live log at the bottom expands for troubleshooting.

The panel look is provided by ESPHome's `web_server`; without a `version` it uses the default version (recent ESPHome defaults to v2). For an HA-style interface, add `version: 3` to the config.

## 2.6 Connecting several devices at once

The same firmware can be flashed to any number of devices: it enables `name_add_mac_suffix: true`, so every device appends the last 3 bytes of its own MAC to its name at boot.

| Item | Form |
|:-----|:-----|
| Node name | `esp32pwm22810-a1b2c3` |
| HA device name | `ESP32 PWM 22810 a1b2c3` |
| mDNS | `esp32pwm22810-a1b2c3.local` |
| Entity ID | `<domain>.esp32_pwm_22810_a1b2c3_<entity name>` |

The steps are the same as for a single device, just repeat them; multiple devices coexist as separate entries.

> **Why add the suffix**: HA uses the `name` from the firmware as the unique ESPHome device identifier. When several devices share a name, HA triggers [name-conflict handling](https://www.home-assistant.io/integrations/esphome/#reconfiguration-and-device-replacement) and offers only "migrate" or "overwrite", so the device added later overwrites the existing one.

If you previously added a device with the old same-name firmware, delete the old entry first and add it again. Ways to verify device identity:

1. The last 3 bytes of the MAC address on the HA device page;
2. The hostname in the router's DHCP client list;
3. The MAC printed at the start of the serial log;
4. Open `http://<device IP>/` in a browser; the log area shows the node name.

## Next steps

- Want temperature-driven speed control → [Temperature control](Temperature-Control-EN)
- Want presence-based automation → [mmWave radar](Radar-EN)
- Want to call it from scripts → [HTTP API](HTTP-API-EN)
- Device misbehaving → [Troubleshooting](Troubleshooting-EN)
