# HTTP REST API

[← Home](Home-EN) · [中文](HTTP-API) · **English**

The firmware enables the ESPHome `web_server` (port 80), which provides a simple REST API and a live event stream on top of the web panel. **Home Assistant is not involved**, so this suits scripts, Raspberry Pis, router cron jobs and similar setups.

## URL rules

```text
/<domain>/<entity_name>[/<action>?<param>=<value>]
```

| Part | Notes |
|:-----|:-----|
| `domain` | Component type: `fan`, `sensor`, `switch`, `number`, `select`, `binary_sensor`, `text_sensor`, `button` |
| `entity_name` | **The `name` from the config file, verbatim**, including spaces and Chinese characters |
| `action` | `turn_on` / `turn_off` / `toggle` / `set` / `press` |
| Method | `GET` reads state, `POST` performs an action |

> `entity_name` is the name in the YAML, **not** the `entity_id` in HA. Renaming an entity in HA does not change the API path.

## Endpoint cheat sheet

| Purpose | Method and path | Key parameters |
|:-----|:-----------|:---------|
| Read fan state | `GET /fan/风扇 1` | — |
| Turn fan on and set speed | `POST /fan/风扇 1/turn_on` | `speed_level=1..100` |
| Turn fan off (cut power) | `POST /fan/风扇 1/turn_off` | — |
| Toggle the fan | `POST /fan/风扇 1/toggle` | — |
| Read RPM | `GET /sensor/风扇 1 转速` | — |
| Read temperature | `GET /sensor/温度 A` | — |
| Read radar state | `GET /binary_sensor/雷达检测到目标 Target` | — |
| Read radar distance | `GET /sensor/雷达目标距离 Dist` | — |
| Change temperature-control parameter | `POST /number/风扇1 启控温度 T-Min/set` | `value=30` |
| Change temperature source | `POST /select/风扇1 温度源绑定 F1-Src/set` | `option=温度 A` (needs encoding) |
| Read IP / SSID | `GET /text_sensor/设备 IP 地址` | — |

## Chinese and spaces must be encoded

Browsers encode automatically; scripts have to do it themselves. Taking `风扇 2` as an example:

| Raw | Encoded |
|:-----|:-------|
| `风扇 2` | `%E9%A3%8E%E6%89%87%202` |
| `风扇 2 转速` | `%E9%A3%8E%E6%89%87%202%20%E8%BD%AC%E9%80%9F` |
| `温度 A` | `%E6%B8%A9%E5%BA%A6%20A` |

Query-string parameters such as `?speed_level=50` are pure ASCII and need no encoding.

## Reading state (GET)

```bash
# RPM
curl "http://10.0.20.83/sensor/%E9%A3%8E%E6%89%87%201%20%E8%BD%AC%E9%80%9F"
```

```json
{
  "id": "sensor/风扇 1 转速",
  "state": "1280 RPM",
  "value": 1280
}
```

```bash
# fan
curl "http://10.0.20.83/fan/%E9%A3%8E%E6%89%87%201"
```

```json
{
  "id": "fan/风扇 1",
  "state": "ON",
  "value": true,
  "speed_level": 50
}
```

```bash
# add detail=all to get the name, the available options and other extra fields
curl "http://10.0.20.83/select/%E9%A3%8E%E6%89%871%20%E6%B8%A9%E5%BA%A6%E6%BA%90%E7%BB%91%E5%AE%9A%20F1-Src?detail=all"
```

```json
{
  "id": "select/风扇1 温度源绑定 F1-Src",
  "name": "风扇1 温度源绑定 F1-Src",
  "state": "温度 A",
  "value": "温度 A",
  "option": ["未绑定", "温度 A", "温度 B", "温度 C", "温度 D"]
}
```

## Control (POST)

```bash
# turn fan 2 on at 50%
curl -X POST "http://10.0.20.83/fan/%E9%A3%8E%E6%89%87%202/turn_on?speed_level=50"

# turn fan 2 off (true power cut)
curl -X POST "http://10.0.20.83/fan/%E9%A3%8E%E6%89%87%202/turn_off"

# control parameter: change the trigger temperature to 35°C
curl -X POST "http://10.0.20.83/number/%E9%A3%8E%E6%89%871%20%E5%90%AF%E6%8E%A7%E6%B8%A9%E5%BA%A6%20T-Min/set?value=35"

# set the temperature source to 未绑定 (unbound) and hand control back to manual/HA
curl -X POST "http://10.0.20.83/select/%E9%A3%8E%E6%89%871%20%E6%B8%A9%E5%BA%A6%E6%BA%90%E7%BB%91%E5%AE%9A%20F1-Src/set?option=%E6%9C%AA%E7%BB%91%E5%AE%9A"
```

A successful call returns `200 OK`, usually with an empty body. A `speed_level` outside `1..100` or a `value` outside the parameter's range is ignored.

## Script examples

### Python

```python
import requests
from urllib.parse import quote

BASE = "http://10.0.20.83"

def url(domain, name, action="", **params):
    u = f"{BASE}/{domain}/{quote(name)}"
    if action:
        u += f"/{action}"
    if params:
        u += "?" + "&".join(f"{k}={v}" for k, v in params.items())
    return u

# turn fan 2 on at 50%
requests.post(url("fan", "风扇 2", "turn_on", speed_level=50), timeout=5)

# read the RPM of fan 1
r = requests.get(url("sensor", "风扇 1 转速"), timeout=5)
r.raise_for_status()
print("RPM:", r.json()["value"])

# read all four temperatures
for label in ["A", "B", "C", "D"]:
    r = requests.get(url("sensor", f"温度 {label}"), timeout=5)
    print(label, r.json().get("state"))
```

### PowerShell

```powershell
$base = "http://10.0.20.83"
$fan  = [uri]::EscapeDataString("风扇 2")

# turn the fan on at 50%
Invoke-RestMethod -Method Post -Uri "$base/fan/$fan/turn_on?speed_level=50"

# read the RPM
$rpm = Invoke-RestMethod -Uri "$base/sensor/$([uri]::EscapeDataString('风扇 1 转速'))"
$rpm.value
```

### Node.js

```javascript
const BASE = "http://10.0.20.83";
const fanUrl = (name, action = "", q = "") =>
  `${BASE}/fan/${encodeURIComponent(name)}${action ? "/" + action : ""}${q ? "?" + q : ""}`;

await fetch(fanUrl("风扇 1", "turn_on", "speed_level=80"), { method: "POST" });

const res = await fetch(`${BASE}/sensor/${encodeURIComponent("风扇 1 转速")}`);
console.log((await res.json()).value);
```

### Home Assistant `rest_command`

```yaml
rest_command:
  fan2_speed_50:
    url: "http://10.0.20.83/fan/{{ '风扇 2' | urlencode }}/turn_on?speed_level=50"
    method: POST
```

## Live event stream (/events)

```bash
curl -N "http://10.0.20.83/events"
```

The server pushes three kinds of event over Server-Sent Events:

| Event type | Notes |
|:---------|:-----|
| `ping` | heartbeat that keeps the connection alive |
| `state` | any entity state change; the JSON payload matches the GET response |
| `log` | device log (`web_server`'s `log: true`, enabled by default) |

On connect it pushes the state of all entities once so clients can line up. This suits local dashboards, MQTT bridges and InfluxDB collection — **it uses less device memory than high-frequency polling**.

## Security notes

> The Web Server has **no authentication at all by default**: anyone on the same LAN can control your fans and read the temperatures.

Ways to harden it:

```yaml
web_server:
  port: 80
  auth:
    username: admin
    password: "use a strong password"
    type: digest      # supported by recent ESPHome releases, recommended
```

- Put IoT devices on their own VLAN / SSID and only allow the subnet where HA lives;
- Do not map port 80 to the internet;
- For access across networks, go through HA (API token and TLS) rather than connecting to the device directly;
- If you enable `digest`, update your scripts to digest auth as well (`curl --digest`).

## Performance and limits

| Item | Recommendation |
|:---|:-----|
| Polling interval | ≥ 5 seconds (RPM refreshes every 4 s, temperature every 5 s, diagnostics every 60 s) |
| Concurrent connections | Every connection consumes heap, so keep it to 2–3 long-lived connections |
| Bulk collection | Use `/events` instead of polling from several threads |
| Memory headroom | The v2.0 radar build has the most features and the tightest heap; if the device reboots frequently, cut the Web connections first |
| OTA | The `web_server` in the default config is not used for OTA; upgrade through ESPHome OTA |

## When not to use this API

| Scenario | Better fit |
|:-----|:-------------|
| Automations inside HA | Use the `fan.set_percentage` and `number.set_value` services directly |
| Need authentication, TLS or public access | HA REST API (with a long-lived token) |
| Need MQTT | Add the `mqtt:` component to the config |
| High-frequency, low-latency control | The ESPHome native API (aioesphomeapi) or local HA calls |
