# HTTP REST API

[← 首页](Home) · **中文** · [English](HTTP-API-EN)

固件启用了 ESPHome `web_server`（80 端口），除了网页面板，还提供一套简单的 REST API 和实时事件流。**不经过 Home Assistant**，适合脚本、树莓派、路由器定时任务等场景。

## URL 规则

```text
/<domain>/<entity_name>[/<action>?<param>=<value>]
```

| 部分 | 说明 |
|:-----|:-----|
| `domain` | 组件类型：`fan`、`sensor`、`switch`、`number`、`select`、`binary_sensor`、`text_sensor`、`button` |
| `entity_name` | **配置文件里的 `name` 原文**，包含空格和中文 |
| `action` | `turn_on` / `turn_off` / `toggle` / `set` / `press` |
| 方法 | `GET` 读状态，`POST` 执行动作 |

> `entity_name` 是 YAML 里的名字，**不是** HA 里的 `entity_id`。HA 里重命名实体不会改变 API 路径。

## 端点速查

| 目的 | 方法与路径 | 关键参数 |
|:-----|:-----------|:---------|
| 读风扇状态 | `GET /fan/风扇 1` | — |
| 开风扇并调速 | `POST /fan/风扇 1/turn_on` | `speed_level=1..100` |
| 关风扇（断电） | `POST /fan/风扇 1/turn_off` | — |
| 切换开关 | `POST /fan/风扇 1/toggle` | — |
| 读转速 | `GET /sensor/风扇 1 转速` | — |
| 读温度 | `GET /sensor/温度 A` | — |
| 读雷达状态 | `GET /binary_sensor/雷达检测到目标 Target` | — |
| 读雷达距离 | `GET /sensor/雷达目标距离 Dist` | — |
| 改温控参数 | `POST /number/风扇1 启控温度 T-Min/set` | `value=30` |
| 改温度源 | `POST /select/风扇1 温度源绑定 F1-Src/set` | `option=温度 A`（需编码） |
| 读 IP / SSID | `GET /text_sensor/设备 IP 地址` | — |

## 中文与空格必须编码

浏览器会自动编码，脚本里必须自己做。以「风扇 2」为例：

| 原文 | 编码后 |
|:-----|:-------|
| `风扇 2` | `%E9%A3%8E%E6%89%87%202` |
| `风扇 2 转速` | `%E9%A3%8E%E6%89%87%202%20%E8%BD%AC%E9%80%9F` |
| `温度 A` | `%E6%B8%A9%E5%BA%A6%20A` |

`?speed_level=50` 这类查询串参数是纯 ASCII，不需要编码。

## 读状态（GET）

```bash
# 转速
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
# 风扇
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
# 加 detail=all 可拿到名字、可用选项等附加信息
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

## 控制（POST）

```bash
# 开 2 号风扇并设到 50%
curl -X POST "http://10.0.20.83/fan/%E9%A3%8E%E6%89%87%202/turn_on?speed_level=50"

# 关 2 号风扇（真正断电）
curl -X POST "http://10.0.20.83/fan/%E9%A3%8E%E6%89%87%202/turn_off"

# 温控参数：起控温度改成 35°C
curl -X POST "http://10.0.20.83/number/%E9%A3%8E%E6%89%871%20%E5%90%AF%E6%8E%A7%E6%B8%A9%E5%BA%A6%20T-Min/set?value=35"

# 温度源改成「未绑定」（放弃本地温控，交给手动/HA）
curl -X POST "http://10.0.20.83/select/%E9%A3%8E%E6%89%871%20%E6%B8%A9%E5%BA%A6%E6%BA%90%E7%BB%91%E5%AE%9A%20F1-Src/set?option=%E6%9C%AA%E7%BB%91%E5%AE%9A"
```

成功返回 `200 OK`，响应体通常为空。`speed_level` 超出 `1..100` 或 `value` 超出参数范围时会被忽略。

## 脚本示例

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

# 开 2 号风扇到 50%
requests.post(url("fan", "风扇 2", "turn_on", speed_level=50), timeout=5)

# 读 1 号风扇转速
r = requests.get(url("sensor", "风扇 1 转速"), timeout=5)
r.raise_for_status()
print("RPM:", r.json()["value"])

# 读 4 个温度
for label in ["A", "B", "C", "D"]:
    r = requests.get(url("sensor", f"温度 {label}"), timeout=5)
    print(label, r.json().get("state"))
```

### PowerShell

```powershell
$base = "http://10.0.20.83"
$fan  = [uri]::EscapeDataString("风扇 2")

# 开风扇到 50%
Invoke-RestMethod -Method Post -Uri "$base/fan/$fan/turn_on?speed_level=50"

# 读转速
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

## 实时事件流（/events）

```bash
curl -N "http://10.0.20.83/events"
```

服务器以 Server-Sent Events 推送三类事件：

| 事件类型 | 说明 |
|:---------|:-----|
| `ping` | 心跳，保持连接 |
| `state` | 任意实体状态变化，JSON 负载与 GET 响应一致 |
| `log` | 设备日志（`web_server` 的 `log: true`，默认开启） |

连接建立时会先推送一次全部实体状态，便于客户端对齐。适合做本地看板、MQTT 桥接、InfluxDB 采集——**比高频轮询更省设备内存**。

## 安全提示

> Web Server **默认没有任何鉴权**：同一局域网内任何人都能控制你的风扇、读取温度。

加固手段：

```yaml
web_server:
  port: 80
  auth:
    username: admin
    password: "换一个强密码"
    type: digest      # 新版 ESPHome 支持，推荐
```

- 给 IoT 设备单独 VLAN / SSID，只放行 HA 所在网段；
- 不要把 80 端口映射到公网；
- 需要跨网访问时，走 HA（有 API 令牌与 TLS），不要直连设备；
- 用 `digest` 时，脚本要同步改成 digest 认证（`curl --digest`）。

## 性能与限制

| 项 | 建议 |
|:---|:-----|
| 轮询间隔 | ≥ 5 秒（转速 4s、温度 5s、诊断 60s 才刷新） |
| 并发连接 | 每个连接都会占用堆内存，别超过 2–3 个长连接 |
| 大批量采集 | 用 `/events`，不要多线程轮询 |
| 内存余量 | v2.0 雷达版功能最多，堆内存最紧；发现设备频繁重启先减少 Web 连接 |
| OTA | 默认配置的 `web_server` 不用于 OTA，升级走 ESPHome OTA |

## 什么时候不该用这套 API

| 场景 | 更合适的方式 |
|:-----|:-------------|
| HA 内做自动化 | 直接用 `fan.set_percentage`、`number.set_value` 服务 |
| 需要认证/TLS/公网访问 | HA REST API（带长期令牌） |
| 需要 MQTT | 在配置中加 `mqtt:` 组件 |
| 高频、低延迟控制 | ESPHome 原生 API（aioesphomeapi）或 HA 本地调用 |
