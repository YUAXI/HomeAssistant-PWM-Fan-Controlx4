# mmWave radar (LD2402G)

[← Home](Home-EN) · [中文](Radar) · **English**

Enabled only in the `v2.0-ds18b20-radar` firmware. The radar performs **human presence detection** and hands two entities — "presence" and "distance" — to Home Assistant, leaving the linkage logic to you.

## Wiring

| Radar pin | Controller pin | Notes |
|:---------|:-----------|:-----|
| TX | GPIO4 (UART RX) | Radar → controller |
| RX | GPIO5 (UART TX) | Controller → radar |
| VCC | 5V (v2.0 4PIN developer header) | Keep an eye on current headroom |
| GND | GND | Common ground |

Serial settings: **115200 8N1**. TX/RX are crossed — connect them the wrong way round and you will see no data at all in the log.

## Serial behaviour

### Power-on initialisation

At boot (`on_boot`, `priority: -100`) the firmware sends two frames first, 200 ms apart:

```text
55 5A 02 01 AA    # enable reporting / config frame
55 01 01 00 AA    # reporting enable
```

If the radar produces no output, first check that these two frames were sent (the serial log prints "正在发送激活指令给 LD2402G...", i.e. sending the activation command to the LD2402G).

### Report format

The radar outputs distance as ASCII lines, and the firmware parses them line by line:

```text
distance:35\r\n     → 0.35 m
distance:180\r\n    → 1.80 m
```

Parsing rules: split lines on `0x0A` (`\n`), ignore `0x0D` (`\r`), take the centimetre value with `sscanf("distance:%d")`, then divide by 100 to get metres.

### Why `uart.debug` instead of the standard UART component

The radar only needs **receiving** (the controller barely parses the binary protocol), so the firmware uses:

```yaml
uart:
  - id: radar_uart
    tx_pin: GPIO5
    rx_pin: GPIO4
    baud_rate: 115200
    debug:
      direction: RX
      dummy_receiver: true     # bytes only reach the lambda, no real UART device is created
      sequence:
        - lambda: |-
            ...自定义解析...
```

`dummy_receiver: true` means the byte stream goes straight into the lambda's `bytes` and no UART device object is created. **This UART therefore cannot host another UART component at the same time** (to add RS485, open a second UART on other pins).

## Anti-interference algorithm

The raw radar distance jitters and contains fixed reflections (metal cabinets, the chassis), so the firmware applies three filtering layers:

| Rule | Condition | Result |
|:-----|:-----|:-----|
| ① Range filter | distance < `Min` or > `Max` | target = no one, distance = `NaN` |
| ② Change detection | difference from the previous distance **> 0.01 m** | refresh "last change time" and record the new distance |
| ③ Static timeout | inside the range but unchanged for **5 seconds** | judged a fixed false target → no one, distance = `NaN` |

When all three pass: target = present, distance = current reading.

```text
reading → outside [Min, Max]? ──yes──→ no one / distance NaN
              │no
              ↓
      distance changed > 1cm? ──yes──→ update timestamp
              ↓
      more than 5s since last change? ──yes──→ no one / distance NaN (fixed reflection)
              │no
              ↓
            present / distance = reading
```

**Design trade-off**: a person sitting still (change < 1 cm for 5 seconds) is judged "no one". This suppresses fixed-reflection noise at the cost of no true static presence detection. If you need a longer stillness tolerance, just change the `5000` millisecond constant in the firmware:

```cpp
if (millis() - last_change_time > 5000) {   // increase it, e.g. 30000
```

> The current firmware only uses the radar's ASCII distance reports, not its binary / presence-detection protocol; the "present" decision is made entirely by the logic above.

## Parameters

| Parameter | Range | Step | Default | Function |
|:-----|:-----|:-----|:----:|:-----|
| 雷达 最近过滤门限 Min | 0.0–2.0 m | 0.05 | 0.10 m | Reflections closer than this are ignored (face-level false triggers, reflections inside the chassis) |
| 雷达 最远过滤门限 Max | 0.5–8.0 m | 0.1 | 1.50 m | Reflections farther than this are ignored (the next room, the end of the corridor) |

Both parameters survive power loss and can be dragged at any time in HA, taking effect immediately (on the next report cycle).

How to tune:

1. First watch the live value of `雷达目标距离 Dist` (walk around the target spot and read it);
2. Set `Min` to the near edge of the target area (say 0.3 m in front of the chair);
3. Set `Max` to the far side of the room (say 2.5 m) to block out the corridor and the neighbours;
4. Verify: "sit still for 10 s" → should flip to "no one"; "wave your hand" → immediately "present".

## Entities

| Entity | Type | Notes |
|:-----|:-----|:-----|
| 雷达检测到目标 Target | binary_sensor | present = `on`; filtered out = `off` |
| 雷达目标距离 Dist | sensor | unit m; publishes `NaN` when filtered out (HA shows unknown) |

## Linkage examples

### Faster when present, slower when away

```yaml
alias: "机柜风扇：有人全速，无人降速"
mode: restart
trigger:
  - platform: state
    entity_id: binary_sensor.esp32_pwm_22810_a1b2c3_lei_da_jian_ce_dao_mu_biao_target
action:
  - choose:
      - conditions:
          - condition: state
            entity_id: binary_sensor.esp32_pwm_22810_a1b2c3_lei_da_jian_ce_dao_mu_biao_target
            state: "on"
        sequence:
          - service: fan.set_percentage
            target: { entity_id: fan.esp32_pwm_22810_a1b2c3_feng_shan_1 }
            data: { percentage: 100 }
      - conditions:
          - condition: state
            entity_id: binary_sensor.esp32_pwm_22810_a1b2c3_lei_da_jian_ce_dao_mu_biao_target
            state: "off"
            for: "00:02:00"          # wait 2 minutes with nobody present before slowing down, to avoid false triggers
        sequence:
          - service: fan.set_percentage
            target: { entity_id: fan.esp32_pwm_22810_a1b2c3_feng_shan_1 }
            data: { percentage: 30 }
```

> The `entity_id`s above are only illustrative; copy the real IDs from your own HA entity page (the Chinese names are kept inside the IDs).

### Combining it correctly with local temperature control

Do not write the fan speed directly from HA — if that fan has a temperature source bound, the local closed loop overwrites it 5 seconds later. Recommended:

| Need | Approach |
|:-----|:-----|
| More aggressive cooling when someone is present | Use `number.set_value` to change `F-Max` (e.g. 100), and 60 when no one is around |
| Less noise when someone is present | Set `F-Min` to 25 so that any spin is low-noise from the start |
| Full control of one channel | Set that channel's `FN-Src` to **未绑定** (unbound), then let the HA automation drive the fan |

```yaml
action:
  - service: number.set_value
    target: { entity_id: number.esp32_pwm_22810_a1b2c3_feng_shan_1_zui_gao_feng_su_f_max }
    data: { value: 100 }
```

## Troubleshooting

| Symptom | Check |
|:-----|:-----|
| Dist stays unknown | Are TX/RX swapped; is the radar powered from 5V; is there any `distance:` line in the serial log |
| Always shows present | `Min` too small (reflections inside the chassis); `Max` too large (the corridor next door); look at the actual Dist value first |
| Always shows no one | The person stands outside `[Min, Max]`; or the distance change is < 1 cm and gets eaten by the static check |
| Value jumps back and forth | Normal — radar resolution is about 1 cm; add a `for:` delay in your automations to debounce |
| Log spammed with radar data | Normal (`uart.debug` prints the bytes sent and received); just keep `logger.level` at `INFO` |
| No radar data after a reboot | Check whether both `on_boot` frames were sent (the log shows "正在发送激活指令…") |

## Power notes

The radar, the 4 fans and the 4 temperature probes all draw from the board's 5V/3.3V rails:

- Budget more than 100mA of peak current for the radar module;
- The 4 fans at full load run off the 12V rail and are unrelated to the radar;
- If the radar reboots often or its data drops out, measure the 5V rail first (TPS5430 output) and check the 4PIN header contact.
