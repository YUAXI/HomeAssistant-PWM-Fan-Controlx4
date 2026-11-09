# Entity Reference

[← Home](Home-EN) · [中文](Entities) · **English**

Every `name` in the firmware becomes an entity in HA and also appears in the web panel and the REST API. This page is the complete entity list with defaults.

## Naming rules

| Level | Example |
|:-----|:-----|
| `name` in the config file | `风扇 1` |
| Entity name in the web UI / REST API | `风扇 1` (identical to the YAML, spaces and Chinese included) |
| HA device name | `ESP32 PWM 22810 a1b2c3` |
| HA `entity_id` | `fan.esp32_pwm_22810_a1b2c3_风扇_1` |

- HA's `entity_id` is the device name plus the entity name, slugified; Chinese characters are preserved.
- The actual `entity_id` differs between firmwares and device names, so **go by what the HA entity page shows**; you can rename `entity_id` in HA without affecting the firmware.
- To avoid Chinese IDs entirely, change `name` to ASCII in the config (see [Firmware versions](Firmware-EN#custom-compilation)).

## Fans (fan)

| Entity name | Firmware id | Description |
|:-------|:----------|:-----|
| 风扇 1 | `my_fan1` | PWM = GPIO16, power = GPIO21 |
| 风扇 2 | `my_fan2` | PWM = GPIO17, power = GPIO22 |
| 风扇 3 | `my_fan3` | PWM = GPIO18, power = GPIO23 |
| 风扇 4 | `my_fan4` | PWM = GPIO19, power = GPIO13 |

| Property | Value |
|:-----|:---|
| Type | `speed` (speed control with levels) |
| Number of levels | `speed_count: 100` → speed levels 1–100 |
| Restore on power-up | `RESTORE_DEFAULT_OFF` (off by default) |
| On | Turn on the TPS22810 load switch to power the fan, then output PWM |
| Off | Stop PWM first, then cut the load switch (a real power-off, not 0% duty cycle) |
| RPM when off | RPM drops to 0 (the fan is unpowered) |

> The 4 power switches (`fan1_pwr`–`fan4_pwr`) are `internal: true` and **do not** appear in HA / the web UI / the API; the fan entities drive them automatically.

## Sensors (sensor)

| Entity name | Unit | Refresh | Firmware | Description |
|:-------|:-----|:-----|:---------|:-----|
| 风扇 1 转速 | RPM | 4s | All | `pulse_counter`, falling-edge counting |
| 风扇 2 转速 | RPM | 4s | All | same as above |
| 风扇 3 转速 | RPM | 4s | All | same as above |
| 风扇 4 转速 | RPM | 4s | All | same as above |
| 温度 A | °C | 5s | DS18B20 / radar | 1-Wire index 0 |
| 温度 B | °C | 5s | DS18B20 / radar | 1-Wire index 1 |
| 温度 C | °C | 5s | DS18B20 / radar | 1-Wire index 2 |
| 温度 D | °C | 5s | DS18B20 / radar | 1-Wire index 3 |
| 雷达目标距离 Dist | m | event-driven | Radar | publishes `NaN` when nobody is present / out of range (HA shows unknown) |
| 设备运行时间 | s | 60s | All | diagnostic entity |
| Wi-Fi 信号强度 | dBm | 60s | All | diagnostic entity |

RPM conversion: each fan revolution produces **2** tach pulses, and the firmware uses `multiply: 0.5` to convert "pulses per minute" into RPM. If a fan actually outputs 1 pulse per revolution, the reading comes out half as high; change `multiply` in the config.

## Text sensors (text_sensor)

| Entity name | Firmware | Description |
|:-------|:---------|:-----|
| 设备 IP 地址 | All | diagnostic entity, updated when DHCP changes the IP |
| 连接 Wi-Fi SSID | All | diagnostic entity |
| ESPHome 版本 | All | diagnostic entity, reflects the ESPHome version used at build time |

## Binary sensors (binary_sensor)

| Entity name | Firmware | Description |
|:-------|:---------|:-----|
| 雷达检测到目标 Target | Radar | someone present = `on`. Decision logic in [mmWave radar](Radar-EN#anti-interference-algorithm) |

## Numbers (number)

### Temperature-control parameters (4 per fan channel, 16 in total)

| Entity name format | id | Range | Step | Default | Unit |
|:-----------|:---|:-----|:-----|:-----|:-----|
| 风扇N 启控温度 T-Min | `fN_t_min` | 10–60 | 1 | 30 | °C |
| 风扇N 满载温度 T-Max | `fN_t_max` | 40–90 | 1 | 50 | °C |
| 风扇N 最低风速 F-Min | `fN_f_min` | 0–50 | 1 | 0 | % |
| 风扇N 最高风速 F-Max | `fN_f_max` | 50–100 | 1 | 100 | % |

`N` is 1–4. All of them use `restore_value: true` and survive power loss.

### Radar parameters (radar firmware only, 2)

| Entity name | id | Range | Step | Default | Unit |
|:-------|:---|:-----|:-----|:-----|:-----|
| 雷达 最近过滤门限 Min | `radar_min_dist` | 0.0–2.0 | 0.05 | 0.10 | m |
| 雷达 最远过滤门限 Max | `radar_max_dist` | 0.5–8.0 | 0.1 | 1.5 | m |

## Selectors (select)

| Entity name | id | Options | Default |
|:-------|:---|:-------|:-----|
| 风扇1 温度源绑定 F1-Src | `f1_source` | 未绑定 / 温度 A / 温度 B / 温度 C / 温度 D | 温度 A |
| 风扇2 温度源绑定 F2-Src | `f2_source` | same as above | 温度 B |
| 风扇3 温度源绑定 F3-Src | `f3_source` | same as above | 温度 C |
| 风扇4 温度源绑定 F4-Src | `f4_source` | same as above | 温度 D |

`restore_value: true`, so the selected temperature source survives power loss.

## Entity counts per firmware

| Entity type | v1.0 | v2.0 Basic | v2.0 DS18B20 | v2.0 radar |
|:---------|:----:|:----------:|:------------:|:---------:|
| fan | 4 | 4 | 4 | 4 |
| sensor | 6 | 6 | 10 | 11 |
| text_sensor | 3 | 3 | 3 | 3 |
| binary_sensor | 0 | 0 | 0 | 1 |
| number | 0 | 0 | 16 | 18 |
| select | 0 | 0 | 4 | 4 |
| **Total** | **13** | **13** | **37** | **41** |

(Diagnostic entities are already counted under sensor / text_sensor; `internal: true` power switches are not counted.)

## Persistence and restore

| Data | Storage location | Behaviour |
|:-----|:---------|:-----|
| Temperature-control parameters, radar thresholds | ESP32 NVS | `restore_value: true`, kept across reboots |
| Temperature source binding | NVS | same as above |
| Fan on/off state and speed | not saved | off after every power-up (`RESTORE_DEFAULT_OFF`) |
| Wi-Fi credentials | NVS | kept; falls back to the hotspot if it cannot connect |

> A normal OTA upgrade preserves the NVS; a full-chip flash with `.factory.bin` (including the partition table) clears the parameters back to their defaults.

## Can't find an entity?

1. **Diagnostic entities** are collapsed into the device's "Diagnostics" section in HA, not on the main control card;
2. Entities marked `internal: true` are never exposed (only the 4 power switches);
3. Temperature / radar / parameter entities only exist in the matching firmware; Basic and v1.0 do not have them;
4. When entity names are duplicated HA appends a `_2` suffix; search the entity list for 风扇 to confirm.
