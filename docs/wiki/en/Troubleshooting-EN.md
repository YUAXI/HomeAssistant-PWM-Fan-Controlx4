# Troubleshooting

[← Home](Home-EN) · [中文](Troubleshooting) · **English**

## Four things to do first

1. **Check the serial log**: connect Type-C to a computer, open the port with `esphome logs <config>` or any serial tool (115200). If you see boot logs, the hardware is alive.
2. **Check the web panel**: `http://<device IP>/`. If it loads, Wi-Fi and firmware are fine.
3. **Check the HA entities**: is 设备运行时间 (uptime) on the device page increasing? (Back to zero = the device rebooted.)
4. **Confirm the firmware variant**: flashing single-core/dual-core firmware to the wrong board is the most common cause of "won't boot".

## Device does not boot / hotspot not found

| Check | Details and fix |
|:-----|:-----------|
| Power | DC 12V is required; Type-C 5V is only for flashing and debugging, cannot drive fans, and some boards cannot even boot reliably on 5V alone |
| Wrong firmware | `v1.0 双核` firmware on a single-core device **will not boot**. Reflash `v1.0 单核` or any `v2.0` build over USB |
| Corrupt partition table | Flashing only `.firmware.bin` (the app image) to `0x0` produces an unbootable image → flash `.factory.bin` to `0x0` |
| Button stuck | Holding BOOT (IO0) enters download mode; release it and power-cycle |
| Module power | Feel whether the ESP32 module gets unusually hot; measure the 3.3V rail (3.2–3.4V) |

## Serial port not recognized / flashing fails

| Symptom | Cause | Fix |
|:-----|:-----|:-----|
| No `CH340` in Device Manager | Missing driver / charge-only cable | Install the WCH CH340 driver; use a Type-C cable that carries data |
| `Failed to connect to ESP32` | Not in download mode | Hold BOOT → press RST → release BOOT, then flash again |
| `Timed out waiting for packet header` | Baud rate too high | Drop to `--baud 115200` |
| `Serial port busy` / access denied | Serial port in use | Close ESPHome Dashboard, Arduino IDE, serial terminals, etc. |
| Flashing fails midway | Insufficient USB power / poor cable | Use another USB port (prefer a rear port on the motherboard) and disconnect the fan load |
| Linux permission error | No serial permission | `sudo usermod -aG dialout $USER`, then log in again |

Standard recovery procedure:

```bash
# 1. enter download mode: hold BOOT, tap RST, release BOOT
# 2. flash the factory image to the whole chip
esptool.py --chip esp32 --port COM5 --baud 115200 write_flash 0x0 \
  v1.0-single-core.firmware.factory.bin

# 3. if that still fails, erase the whole flash first
esptool.py --chip esp32 --port COM5 erase_flash
```

## Provisioning fails / cannot join Wi-Fi

| Symptom | Fix |
|:-----|:-----|
| Hotspot `ESP32-Fan-22810` does not appear | The device is still running an old Wi-Fi configuration; after a power cycle it falls back to hotspot mode if it cannot connect within 60 seconds. Or the device is not booting at all (see the previous section) |
| 192.168.4.1 does not open | After joining the hotspot, turn off mobile data; use the `http://` prefix, not https |
| Spinner keeps spinning after entering the password | Only **2.4GHz** Wi-Fi is supported, 5GHz will not connect; check the password and make sure the router has no MAC allow-list enabled |
| Connects but drops quickly | Signal too weak (< −80 dBm); move the device or add an AP; enterprise Wi-Fi (802.1X) is not supported |
| Lost after changing the Wi-Fi password | Power-cycle to fall back to hotspot mode and provision again |

## HA does not discover the device

| Check | Fix |
|:-----|:-----|
| Subnet | HA and the device must be able to reach each other; mDNS does not cross VLANs, so use "enter IP manually" instead |
| Can the browser open `http://<IP>/` | If not → the problem is on the device side, not in HA |
| Was the API key changed | Use the key currently in the configuration; if unsure, reflash the official firmware |
| Is the ESPHome integration installed in HA | Settings → Devices & services → Add integration → ESPHome |
| Port blocked | The native API uses 6053 and also fails when a firewall blocks it |

## Duplicate entities / devices overwriting each other

**Cause**: several devices share the same `name` (older firmware had no MAC suffix).

**Fix**:

1. Delete the old ESPHome entry in HA;
2. Upgrade to firmware with `name_add_mac_suffix: true` enabled (all current builds enable it);
3. Add the device again — the device name now carries the MAC suffix, so multiple units can coexist.

## Fan does not spin

Check in this order:

| Step | Check |
|:-----|:-------|
| 1 | Is the fan `on` in HA/Web? Is the speed level > 0? |
| 2 | Does it spin when set to 100% manually? — If not, it is a power/wiring problem, not a speed-control problem |
| 3 | Is the power switch following along: the fan entity's `on_turn_on` turns on `fanN_pwr` (TPS22810 EN). Use a multimeter to check for 12V between fan connector Pin2 and GND |
| 4 | Does the fan use the standard 4PIN pinout? Reversing 12V/GND destroys components |
| 5 | With a 3PIN fan and no PWM wire, even 1% may not spin it (some fans run at full speed with PWM floating, others stop) |
| 6 | Is a temperature source bound? Is `T-Min` above the current temperature? → The local closed loop actively cuts power (see [temperature control](Temperature-Control-EN#manual-control-vs-local-closed-loop)) |
| 7 | `F-Min = 0` and the temperature just crossed the threshold → the result is 0%, which means off |
| 8 | Does the fan spin when fed 12V directly? If not, the fan is dead |

## RPM is 0 or jumps around

| Symptom | Cause | Fix |
|:-----|:-----|:-----|
| On but RPM is 0 | Tach wire not connected / fan has no Tach / missing pull-up on that channel | Use a 4PIN fan; check the soldering of GPIO32/33/25/26 |
| RPM jumps ±20% | Too few pulses at low speed (few pulses per 4 seconds, large quantization error) | Normal; or increase `update_interval` and add `sliding_window_moving_average` filtering |
| RPM is exactly half | The fan outputs 1 pulse per revolution | Change `multiply: 0.5` to `1.0` |
| RPM sticks at a high value | Tach picks up interference / missing pull-up causes false counts | Check the 10kΩ pull-up and the routing |
| Fan stopped but a reading remains | Filtering residue | Wait one refresh cycle (4s) |

## PWM whine / resonance

- 25 kHz is the standard for 4PIN fans and is essentially inaudible to humans, but at low speed the **motor windings** can whine — raising the minimum speed from 1–5% to 20% or more usually eliminates it;
- Sheet-metal resonance in the chassis: mount the fans on silicone dampers, or offset the four fan speeds (`F-Min` differing by 5% each);
- If the whine comes from the power supply: the TPS5430 may enter pulse-skipping mode at light load. This is normal — add load or ignore it.

## Temperature control has no effect

| Check | Explanation |
|:-----|:-----|
| Is `FN-Src` set to `未绑定` (unbound) | A–D is bound by default, but if you have set "unbound" manually, no temperature control runs |
| Is the temperature `unknown` | Probe not connected / no pull-up / index shifted → the algorithm keeps the current state |
| `T-Min` ≥ `T-Max` | The firmware does not validate this; the "≤ T-Min → stop" branch matches first, so the fan never spins |
| `F-Min = 0` | Just above the threshold the computed value is 0% → treated as off |
| Was the fan changed manually in HA | The closed loop overrides it within 5 seconds — this is normal |
| Are the parameters scrambled | Restore the 5 parameters to their defaults via HA/Web (30 / 50 / 0 / 100) |

## Temperature readings are abnormal

| Symptom | Fix |
|:-----|:-----|
| All temperatures `unknown` | Check that GPIO14 is wired correctly, that there is a 4.7kΩ pull-up, and that the probe is powered from 3.3V/5V |
| Some `unknown` | One probe has a bad connection; indices shift, so switch to a fixed `address` |
| Readings clearly off | Voltage drop/interference on long cables; use shielded cable and shorten the bus |
| `温度 A`–`温度 D` do not match the physical positions | Index ordering issue, see [temperature control](Temperature-Control-EN#indexes-and-temperature-ad) |
| Updates are very slow | Fixed at 5 seconds; the 4 probes share one bus, so this is normal |

## Radar problems

| Symptom | Fix |
|:-----|:-----|
| Distance stays `unknown` | TX/RX swapped, no 5V supply, wrong baud rate; check whether the log has a `distance:` line |
| Always "occupied" | `Min` too small / `Max` too large; first narrow the range to the target area and observe again |
| Always "unoccupied" | The person is outside `[Min, Max]`, or has been motionless for more than 5 seconds and is classified as a false target |
| Values jitter | Radar resolution is about 1cm; add `for:` debouncing in automations |
| Log spam | Normal `uart.debug` behaviour; `logger.level: INFO` is enough |

## Web panel does not open / API 404

| Symptom | Cause |
|:-----|:-----|
| Home page does not open | IP changed (check the router), port 80 taken (impossible — it is the device itself), firewall between subnets |
| API returns 404 | Entity name misspelled, or not URL-encoded. The name must match the YAML `name` **exactly** (including spaces) |
| API returns 400/405 | Wrong action name (it should be `turn_on`/`turn_off`/`toggle`/`set`/`press`), or a GET was used to write to that endpoint |
| Returns `401` | `web_server.auth` is enabled in the configuration and the script sends no credentials |
| Occasional timeouts | Too many connections / device memory pressure; reduce concurrency and polling frequency |

## OTA fails

| Symptom | Fix |
|:-----|:-----|
| Authentication failure | Wrong OTA password: `4283bb50a8cd66774ce91d2c9d412cf2` |
| Device not found | Use the IP instead of the hostname; make sure both are on the same subnet; test with `ping` |
| Transfer drops midway | Weak Wi-Fi signal or unstable power; move closer to the AP or flash over USB |
| Device unreachable after upgrade | Firmware does not match the hardware (single-core/dual-core); recover over USB |
| All parameters lost after upgrade | A full-chip factory flash erased NVS; set the temperature parameters again |

## Device reboots frequently

| Possible cause | Investigation |
|:---------|:-----|
| Insufficient power | The surge from four fans starting together pulls 12V down; use a supply rated 3A or more, and stagger the startups |
| 5V rail overloaded | Radar + probes + BLE load; measure whether 5V drops below 4.8V |
| Watchdog / crash | The serial log shows `Guru Meditation` / `***ERROR***`; update to the latest firmware and post the log |
| Out of memory | The v2.0 radar build has the most features; reduce Web connections and drop `bluetooth_proxy` |
| Check the uptime | Back to zero means a reboot; if it keeps counting, the `unavailable` state came from network hiccups |

## CI build fails

| Symptom | Fix |
|:-----|:-----|
| YAML syntax error | Validate locally first with `esphome config <file>` |
| Component renamed/removed | CI uses the latest ESPHome and upstream major releases break old configurations; reproduce locally with `pip install -U esphome`, then fix the configuration |
| Firmware artifact not found | The `.esphome/build/<name>/` path changed; CI falls back to `find "$SRC_DIR/.esphome" -name "firmware*.bin"` |
| Fails only in CI | Check whether the build depends on uncommitted local files (`.gitignore` ignores `.esphome`) |

## Still stuck?

Collect the following information before asking — it makes diagnosis much faster:

```text
1. Firmware version (the 「ESPHome 版本」 entity in HA / the release name)
2. Hardware revision (v1.0 / v2.0, single-core / dual-core)
3. Serial boot log (first 40 lines + the error section)
4. Screenshots of the relevant entity states in HA
5. Reproduction steps (what you did → what you expected → what actually happened)
```
