# Frequently Asked Questions (FAQ)

[← Home](Home-EN) · [中文](FAQ) · **English**

## Hardware and loads

### How big a fan can it drive?

All 4 channels are standard 4-pin 12V fan headers. As a rule of thumb:

| Item | Recommendation |
|:-----|:-----|
| Continuous current per channel | ≤ 1A (roughly a 120 mm server fan at half speed or less) |
| All four channels combined | ≤ 2.5A |
| Power supply | 12V / 3A or more; prefer an adapter with overcurrent protection |
| Startup inrush | High-power fans can draw 2–3× their rated current at startup; starting all four at once is the most likely to trip protection |

Over-speccing usually shows up as a reboot at startup, a speed step dropping out, or a hot load switch.

### Does it support 24V fans?

No. Both the DC input and the fan power rail are 12V, so connecting 24V directly will destroy components. If you need 24V fans, design your own buck/switch stage; modifying the production board is not recommended.

### Can I connect a water pump, solenoid valve, or LED strip?

Technically, anything within 12V and under the current limit can be switched, but note:

- **Inductive loads** (pumps, solenoid valves, relay coils) must have a suitable flyback diode in parallel, otherwise the reverse spike at turn-off will destroy the switching transistor;
- **LED strips** draw a lot of current when fully on, and PWM dimming will conflict with the 25 kHz fan PWM (visually acceptable, but there may be audible whine);
- This project is designed for fans; modifications are at your own risk.

### Why emphasize "truly powered off and stopped"?

Many fans do not stop at 0 % PWM duty cycle (with PWM left floating they may even run at full speed). This design cuts fan power directly with a load switch, so:

- Once switched off, the fan is completely still and draws zero power;
- "Below T-Min, fully stopped" in temperature control only becomes meaningful this way;
- The downside: you cannot use 0 % duty cycle to achieve "idle speed".

### Can I use a 3-pin fan (no PWM)?

You can connect it, but you can only switch it, not control its speed: with the PWM pin floating, fans usually run at full speed, and some fans will stop instead. Use a 4-pin fan if you want speed control.

### Why doesn't the fan spin at 1% speed?

Fans have a minimum starting voltage; 1–10 % duty cycle is often not enough to get them spinning (it may also produce a humming noise). The fix: set `F-Min` to the lowest value at which the fan starts (20–30 % for most fans), and don't go below that in manual control either.

## Temperature and radar

### Do I have to connect 4 × DS18B20?

No. Anywhere from 1 to 4 works; unconnected slots show `unknown`, and the corresponding temperature-control logic will "keep the current state". But note that **the indexes change with the number of probes**, so for long-term deployments use a fixed `address` (see [temperature control](Temperature-Control-EN#indexes-and-temperature-ad)).

### How long can the temperature probe cable be?

At 3.3V, 1-Wire is best kept to ≤ 3–5 m, with a 4.7kΩ pull-up and twisted-pair cable. For longer runs use shielded cable and lower the refresh rate.

### Can I use local temperature control and HA automations at the same time?

Not on the same fan channel: they will overwrite each other, because the local closed loop writes the fan state every 5 seconds. The right approach:

- Let the local closed loop handle basic cooling;
- Let HA only "change parameters" (`T-Min`/`F-Max`) and send notifications;
- If you want HA to take full control, set that channel's `FN-Src` to "未绑定" (unbound).

### Can the radar detect a stationary person?

No (current firmware). The anti-interference algorithm requires the distance to keep changing (> 1 cm); anything that stays still for more than 5 seconds is treated as "no one present". That is how fixed-reflection noise is suppressed. If you need stationary detection, use a real presence sensor (e.g. a module with a native mmWave presence protocol) or raise the 5-second threshold in the firmware.

### Will the radar and 2.4G Wi-Fi interfere with each other?

The radar operates at 24 GHz, a different band from 2.4 GHz Wi-Fi, so interference is basically nil. What actually deserves attention is the 5V supply to the radar module and metal obstructions.

## Software and ecosystem

### Can I use it without Home Assistant?

Yes, it runs completely standalone:

- **Web panel**: `http://<device IP>/` to control fans, view RPM, and adjust parameters;
- **Local temperature control**: the v2.0 DS18B20 firmware has the closed loop built in and works without a network;
- **HTTP API**: for scripts or your own platform.

### Can I use MQTT?

Yes, add it to the config yourself:

```yaml
mqtt:
  broker: 192.168.1.10
  username: mqtt
  password: "your-password"
```

All entities are exposed through MQTT Discovery; no extra code changes are needed.

### Does it support HomeKit / Mi Home / Tuya?

- **HomeKit**: HA's HomeKit Bridge integration can export the fan to the iOS Home app;
- **Mi Home / Tuya**: no native support; you need HA or a self-built bridge.

### Will the firmware update itself?

No. ESPHome devices do not update themselves; you must actively OTA them from HA/CLI, or reflash over USB. In production, pin a version instead of upgrading blindly.

### What is that string of letters after the device name?

In `esp32pwm22810-a1b2c3`, `a1b2c3` is the last 3 bytes of this device's MAC address, appended automatically by `name_add_mac_suffix: true`. It keeps multiple devices flashed with the same firmware from overwriting each other in HA.

### How do I restore factory settings?

| Method | Effect |
|:-----|:-----|
| Delete the ESPHome entry in HA and re-add it | Resets only the HA side; the device is unchanged |
| Flash `.firmware.factory.bin` over USB (`0x0`) | Resets the application and partition table; Wi-Fi and parameters are erased |
| `esptool.py erase_flash` and then reflash | Wipes everything (including NVS) |
| Clear parameters only | Just set the parameters back to their defaults in HA/Web |

### Can I change the device/entity names without reflashing?

- **Rename on the HA side**: any time, effective immediately, does not affect firmware or the API;
- **Rename inside the firmware**: requires a recompile and reflash, turns the old entities `unavailable`, and you have to tidy up the dashboards.

### How many devices can run at the same time?

There is no hard limit; it depends on the Wi-Fi environment and HA load. Keep in mind:

- Every device's mDNS, BLE scanning, and web connections consume resources;
- With more than 20 devices on the same subnet, consider disabling `bluetooth_proxy` on some of them;
- Each device exposes 13–41 entities in HA, so evaluate the total entity count against recorder pressure.

### Is there a case or finished product for sale?

The repository provides 3D-printed parts for v1.0 / v2.0 (STEP + SolidWorks source files) and PCB project files, so you can prototype and print them yourself. Whether finished products are sold is subject to the repository author's announcements.

### Can I use it commercially?

The code and hardware design are released under the [MIT License](https://github.com/YUAXI/HomeAssistant-PWM-Fan-Controlx4/blob/master/LICENSE), which allows commercial use, modification, and redistribution as long as the copyright notice is kept.

## Extending

### Can I extend it to 8 channels?

The ESP32 has limited free GPIOs (this design already uses 15), so adding 4 channels directly requires: a larger package or an IO expander chip (e.g. PCF8574/TCA9555), plus 4 more load switches and a supply branch beyond the TPS5430. On the software side you only need to duplicate the 4 config blocks as described in the [development guide](Development-EN#adding-a-5th-fan), but the hardware has to be redesigned.

### Can I add an OLED display / temperature-humidity sensor?

Yes, just add the corresponding components in ESPHome (`i2c` + `ssd1306` / `sht3xd`). Stay clear of the pins already in use; GPIO27, GPIO2 (boot pin, use with care) and GPIO34/35/36/39 (input only) are available.

### Can I change it to 5V power (running fans from USB power)?

The Type-C 5V is only for flashing and debugging and cannot drive fans. 5V fans are theoretically possible, but you would have to bypass the TPS5430 and verify the load switch and terminal current ratings. That is a hardware modification and out of scope for support.
