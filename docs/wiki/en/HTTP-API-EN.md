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
| `entity_name` | **The `name` from the config file, verbatim**, including spaces. The English firmware uses ASCII names, so only the spaces need encoding |
| `action` | `turn_on` / `turn_off` / `toggle` / `set` / `press` |
| Method | `GET` reads state, `POST` performs an action |

> `entity_name` is the name in the YAML, **not** the `entity_id` in HA. Renaming an entity in HA does not change the API path. Copy the name exactly, including its capitalisation.

## Endpoint cheat sheet

Spaces are written as `%20` below so every path is copy-paste ready. The examples use the English build (`-en`); the Chinese build (`-zh`) uses Chinese entity names instead, see [Encoding rules](#encoding-rules).

| Purpose | Method and path | Key parameters |
|:-----|:-----------|:---------|
| Read fan state | `GET /fan/Fan%201` | — |
| Turn fan on and set speed | `POST /fan/Fan%201/turn_on` | `speed_level=1..100` |
| Turn fan off (cut power) | `POST /fan/Fan%201/turn_off` | — |
| Toggle the fan | `POST /fan/Fan%201/toggle` | — |
| Read RPM | `GET /sensor/Fan%201%20RPM` | — |
| Read temperature | `GET /sensor/Temp%20A` | — |
| Read radar state | `GET /binary_sensor/Radar%20Target%20Detected` | — |
| Read radar distance | `GET /sensor/Radar%20Distance` | — |
| Change temperature-control parameter | `POST /number/Fan%201%20Start%20Temp%20T-Min/set` | `value=30` |
| Change temperature source | `POST /select/Fan%201%20Temp%20Source%20F1-Src/set` | `option=Temp%20A` |
| Read IP / SSID | `GET /text_sensor/IP%20Address` | — |

## Encoding rules

The English firmware uses plain ASCII entity names, so the only character that *must* be encoded is the space (`%20`) — no UTF-8 percent-encoding is needed. The browser normally does this for you; scripts have to do it themselves.

| Raw entity name | Encoded path segment |
|:-----|:-------|
| `Fan 2` | `Fan%202` |
| `Fan 1 RPM` | `Fan%201%20RPM` |
| `Temp A` | `Temp%20A` |
| `Fan 1 Temp Source F1-Src` | `Fan%201%20Temp%20Source%20F1-Src` |
| `Radar Target Detected` | `Radar%20Target%20Detected` |

- Query-string parameters such as `?speed_level=50` are pure ASCII and need no encoding at all; the same goes for select options that contain no space, e.g. `option=Unbound`.
- A raw space in the URL works in some clients but fails in others, so **always write `%20`** in scripts and configs.
- Existing names never contain `%`, `?`, `&`, `#` or `/`, so `%20` is the only escape you need.

> **Chinese builds need full encoding.** The `-zh` releases keep the original Chinese entity names, so their paths must be UTF-8 percent-encoded — both the characters and the spaces. For example the Chinese name for fan 2 becomes `/fan/%E9%A3%8E%E6%89%87%202`, and a select option written as a Chinese phrase needs encoding too. If you use the English build (recommended), ignore this paragraph.

## Reading state (GET)

```bash
# RPM
curl "http://10.0.20.83/sensor/Fan%201%20RPM"
```

```json
{
  "id": "sensor/Fan 1 RPM",
  "state": "1280 RPM",
  "value": 1280
}
```

```bash
# fan
curl "http://10.0.20.83/fan/Fan%201"
```

```json
{
  "id": "fan/Fan 1",
  "state": "ON",
  "value": true,
  "speed_level": 50
}
```

```bash
# add detail=all to get the name, the available options and other extra fields
curl "http://10.0.20.83/select/Fan%201%20Temp%20Source%20F1-Src?detail=all"
```

```json
{
  "id": "select/Fan 1 Temp Source F1-Src",
  "name": "Fan 1 Temp Source F1-Src",
  "state": "Temp A",
  "value": "Temp A",
  "option": ["Unbound", "Temp A", "Temp B", "Temp C", "Temp D"]
}
```

> The `id` field in a response is the human-readable form with spaces, so it is not itself a valid URL — encode the spaces if you feed it back into a request.

## Control (POST)

```bash
# turn fan 2 on at 50%
curl -X POST "http://10.0.20.83/fan/Fan%202/turn_on?speed_level=50"

# turn fan 2 off (true power cut)
curl -X POST "http://10.0.20.83/fan/Fan%202/turn_off"

# control parameter: change the start temperature of fan 1 to 35°C
curl -X POST "http://10.0.20.83/number/Fan%201%20Start%20Temp%20T-Min/set?value=35"

# set the temperature source to Unbound and hand control back to manual/HA
curl -X POST "http://10.0.20.83/select/Fan%201%20Temp%20Source%20F1-Src/set?option=Unbound"
```

A successful call returns `200 OK`, usually with an empty body. A `speed_level` outside `1..100` or a `value` outside the parameter's range is ignored.

## Script examples

### Python

```python
import requests
from urllib.parse import quote

BASE = "http://10.0.20.83"

def url(domain, name, action="", **params):
    # quote() turns the spaces of English names into %20; Chinese names are encoded too
    u = f"{BASE}/{domain}/{quote(name, safe='')}"
    if action:
        u += f"/{action}"
    if params:
        u += "?" + "&".join(f"{k}={quote(str(v), safe='')}" for k, v in params.items())
    return u

# turn fan 2 on at 50%
requests.post(url("fan", "Fan 2", "turn_on", speed_level=50), timeout=5)

# read the RPM of fan 1
r = requests.get(url("sensor", "Fan 1 RPM"), timeout=5)
r.raise_for_status()
print("RPM:", r.json()["value"])

# read all four temperatures
for label in ["A", "B", "C", "D"]:
    r = requests.get(url("sensor", f"Temp {label}"), timeout=5)
    print(label, r.json().get("state"))

# set the temperature source of fan 1
requests.post(url("select", "Fan 1 Temp Source F1-Src", "set", option="Temp A"), timeout=5)
```

### PowerShell

```powershell
$base = "http://10.0.20.83"
$fan  = [uri]::EscapeDataString("Fan 2")     # "Fan%202"

# turn the fan on at 50%
Invoke-RestMethod -Method Post -Uri "$base/fan/$fan/turn_on?speed_level=50"

# read the RPM
$rpm = Invoke-RestMethod -Uri "$base/sensor/$([uri]::EscapeDataString('Fan 1 RPM'))"
$rpm.value

# set the temperature source (options without spaces need no escaping)
Invoke-RestMethod -Method Post -Uri "$base/select/$([uri]::EscapeDataString('Fan 1 Temp Source F1-Src'))/set?option=Unbound"
```

### Node.js

```javascript
const BASE = "http://10.0.20.83";
const fanUrl = (name, action = "", q = "") =>
  `${BASE}/fan/${encodeURIComponent(name)}${action ? "/" + action : ""}${q ? "?" + q : ""}`;

await fetch(fanUrl("Fan 1", "turn_on", "speed_level=80"), { method: "POST" });

const res = await fetch(`${BASE}/sensor/${encodeURIComponent("Fan 1 RPM")}`);
console.log((await res.json()).value);
```

### Home Assistant `rest_command`

```yaml
rest_command:
  fan2_speed_50:
    url: "http://10.0.20.83/fan/{{ 'Fan 2' | urlencode }}/turn_on?speed_level=50"
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
