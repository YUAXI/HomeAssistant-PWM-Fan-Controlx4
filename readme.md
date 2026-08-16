# HomeAssistant-PWM-Fan-Controlx4

<p align="center"><a href="readme.md">中文</a> · <a href="README_EN.md">English</a></p>

## 项目简介

HomeAssistant-PWM-Fan-Controlx4 是一个基于 ESPHome 的 PWM 风扇控制器项目。该控制器支持接入 Home Assistant，实现 4 路风扇的独立调速与智能联动控制。

**主要功能：**

- 通过 ESPHome 集成 Home Assistant 控制
- 4 路风扇独立 PWM 调速及实时转速显示（1-100%），支持**完全关停风扇**
- 支持 Web 网页端 / HTTP REST API 直接控制
- 内置诊断实体（运行时间、Wi-Fi 信号强度、IP 地址、固件版本等）
- v2.0 版本提供 DS18B20 温度传感器接口，支持**本地温度驱动调速**（也可通过 HA 自动化实现）
- v2.0 雷达版本支持 24GHz 毫米波人体存在检测
- 全版本支持**蓝牙代理（BLE Proxy）**，可扩展 Home Assistant 蓝牙覆盖范围

## 更新日志

| 日期 | 更新内容 |
|:-----|:---------|
| 2026-08-16 | 自动调速时温度低于起控温度 T-Min 直接断电完全关停风扇，温度恢复后自动重启 |
| 2026-07-10 | DS18B20 温度读取异常时改为保持当前风速，移除全速保护机制 |
| 2026-07-01 | 全版本新增蓝牙代理功能；CI 自动编译并发布 Release；移除仓库中预编译固件；README 重构 |
| v2.0 | 内置 DS18B20 温度控制、毫米波雷达版本、v2.0 硬件设计 |
| v1.0 | Web 界面控制、HTTP REST API、诊断实体 |

## 项目展示

<div style="text-align: center;">
  <table>
    <tr>
      <td width="25%" style="padding: 10px;">
        <img src="./docs/images/hardware/pcb.jpg" width="450" alt="PCB实物图"/>
      </td>
      <td width="25%" style="padding: 10px;">
        <img src="./docs/images/hardware/physical.jpg" width="450" alt="测试图"/>
      </td>
      <td width="25%" style="padding: 10px;">
        <img src="./docs/images/screenshots/ha01.png" width="250" alt="Home Assistant 控制界面"/>
      </td>
      <td width="25%" style="padding: 10px;">
        <img src="./docs/images/screenshots/ha02.png" width="250" alt="Home Assistant 设备诊断信息"/>
      </td>
    </tr>
  </table>
</div>

---

## 硬件文件

### v2.0 硬件（推荐）

| 类型 | 文件 | 说明 |
|:-----|:-----|:-----|
| PCB Gerber | [gerber.zip](./hardware/v2.0/pcb/gerber.zip) | 可直接发板厂打样 |
| BOM 清单 | [bom.xlsx](./hardware/v2.0/pcb/bom.xlsx) | 物料清单 |
| EDA 工程 | [project.epro2](./hardware/v2.0/pcb/project.epro2) | 立创 EDA 专业版 |
| 外壳主体 | [case.STEP](./hardware/v2.0/3d-models/print/case.STEP) | STEP 格式 3D 模型 |
| 上盖 | [top-cover.STEP](./hardware/v2.0/3d-models/print/top-cover.STEP) | STEP 格式 3D 模型 |

### v1.0 硬件

| 类型 | 文件 |
|:-----|:-----|
| PCB Gerber | [gerber.zip](./hardware/v1.0/pcb/gerber.zip) |
| BOM 清单 | [bom.xlsx](./hardware/v1.0/pcb/bom.xlsx) |
| EDA 工程 | [project.epro2](./hardware/v1.0/pcb/project.epro2) |
| 外壳主体 | [case.step](./hardware/v1.0/3d-models/print/case.step) |
| 上盖 | [top-cover.step](./hardware/v1.0/3d-models/print/top-cover.step) |

---

## 硬件原理

- **风扇电源控制**：使用 `TPS22810DBVR` 芯片直接切断风扇供电，实现风扇**完全停转**，解决普通 PWM 控制器关不掉风扇的问题
- **电源方案**：12V → 5V（`TPS5430DDAR` DC-DC）→ 3.3V（`AMS1117-3.3`），效率高、纹波低
- **USB 转串口**：板载 `CH340C`，Type-C 连接电脑即可烧录

## IO 接口说明

| 风扇 | PWM 输出 | Tach 输入 | 电源管理 |
|:----:|:--------:|:---------:|:--------:|
| Fan1 | GPIO16   | GPIO32    | GPIO21   |
| Fan2 | GPIO17   | GPIO33    | GPIO22   |
| Fan3 | GPIO18   | GPIO25    | GPIO23   |
| Fan4 | GPIO19   | GPIO26    | GPIO13   |

**v2.0 额外接口**：

| 接口 | 说明 |
|:-----|:-----|
| GPIO14（3PIN 排针） | DS18B20 温度传感器 1-Wire 总线 |
| 4PIN 开发者排针（5V / GND / GPIO5 / GPIO4） | 通用扩展接口，可接入 LD2402G 雷达、RS485 模块等外设。雷达版本固件以此接口连接 LD2402G 作为示范 |

---

## 固件版本说明

> ⚠️ 如果你购买的是成品设备，主控采用**单核设计**，**只能刷入 v1.0 单核版本或任意 v2.0 版本**。双核固件必然导致无法启动。

### 版本说明

| 版本 | 核心卖点 | 适用场景 |
|:-----|:---------|:---------|
| **v1.0 双核** | 基础 4 路风扇控制，双核运行 | 已有 HA 自动化、需要更高性能的场合 |
| **v1.0 单核** | 基础 4 路风扇控制，单核低功耗 | 已有 HA 自动化、对功耗敏感 |
| **v2.0 Basic** | 简单风扇控制，单核 | v2.0 硬件用户无需温度与雷达的最低门槛版本 |
| **v2.0 DS18B20** | 内置 DS18B20 温度控制，不依赖 HA 即可自动调速 | 服务器/机柜/NAS 散热，需要本地独立运行 |
| **v2.0 DS18B20+雷达** | 上述功能 + 24GHz 毫米波人体存在检测 | 需要人体感应联动风扇的智能家居场景 |

### 功能对比

| 功能 | v1.0 双核 | v1.0 单核 | v2.0 Basic | v2.0 DS18B20 | v2.0 +雷达 |
|:-----|:--------:|:--------:|:----------:|:------------:|:----------:|
| 4 路 PWM 风扇控制 | ✅ | ✅ | ✅ | ✅ | ✅ |
| 实时转速显示 | ✅ | ✅ | ✅ | ✅ | ✅ |
| Web 界面 / HTTP API | ✅ | ✅ | ✅ | ✅ | ✅ |
| 诊断实体 | ✅ | ✅ | ✅ | ✅ | ✅ |
| 蓝牙代理 | ✅ | ✅ | ✅ | ✅ | ✅ |
| DS18B20 温度控制 | - | - | - | ✅ | ✅ |
| 毫米波雷达 | - | - | - | - | ✅ |
| CPU 核心数 | 双核 | 单核 | 单核 | 单核 | 单核 |

### 如何获取固件

固件由 GitHub Actions 自动编译发布，无需手动打包：

[→ 前往 Releases 下载](https://github.com/YUAXI/HomeAssistant-PWM-Fan-Controlx4/releases)

每个 Release 包含每个版本的三种固件：

| Release 文件名 | 对应版本 |
|:---------------|:---------|
| `v1.0-dual-core.firmware.bin` | v1.0 双核 |
| `v1.0-single-core.firmware.bin` | v1.0 单核 |
| `v2.0-basic.firmware.bin` | v2.0 Basic |
| `v2.0-ds18b20.firmware.bin` | v2.0 DS18B20 |
| `v2.0-ds18b20-radar.firmware.bin` | v2.0 DS18B20+雷达 |

每种固件对应 3 个文件：

| 文件后缀 | 用途 |
|:---------|:-----|
| `.firmware.bin` | 标准固件，常规烧录 |
| `.firmware.factory.bin` | 工厂固件，完整恢复出厂设置 |
| `.firmware.ota.bin` | OTA 远程升级固件 |

**烧录方法**：Type-C 连接电脑，使用 ESPHome 烧录工具或 esptool 烧录。

**自定义编译**：如果你需要修改配置，可用源代码中的 `.yaml` 文件自行编译：

| 版本 | 配置文件 |
|:-----|:---------|
| v1.0 双核 | `firmware/v1.0/dual-core/config.yaml` |
| v1.0 单核 | `firmware/v1.0/single-core/config.yaml` |
| v2.0 Basic | `firmware/v2.0/single-core/basic/config.yaml` |
| v2.0 DS18B20 | `firmware/v2.0/single-core/ds18b20/config.yaml` |
| v2.0 DS18B20+雷达 | `firmware/v2.0/single-core/ds18b20-radar/config.yaml` |

---

## 快速上手指南

> **API 加密密钥**：`LqGIGJ3qyRc+6X6hsMe5vAms+Jyh2lOMh1FQu8yyuzk=`

### 1. 供电与启动

| 供电方式 | 接口 | 电压 | 说明 |
|:---------|:-----|:-----|:-----|
| **DC 接口**（推荐） | DC 座 | 12V/2A+ | 正常运行，可同时为风扇和 ESP32 供电 |
| Type-C 接口 | USB-C | 5V | 仅供烧录/调试，风扇无法工作 |

上电后设备自动创建 Wi-Fi 热点 `ESP32-Fan-22810`（无密码），用手机或电脑连接即可配网。

### 2. 连接 Wi-Fi

1. 连接热点 `ESP32-Fan-22810`
2. 浏览器访问 `http://192.168.4.1` 或 `http://esp32pwm22810.local`
3. 在 Wi-Fi 配置向导中选择家庭/公司 Wi-Fi 并输入密码
4. 设备自动连接并重启

> **提示**：烧录前在 `config.yaml` 中预设 `wifi.ssid` 和 `wifi.password`，设备上电即可自动连接。

### 3. 添加到 Home Assistant

确保已安装 ESPHome 集成，然后：

1. **设置** → **设备与服务** → **添加集成** → 搜索 **ESPHome**
2. 系统会自动发现名为 `ESP32 PWM 22810` 的设备（或手动输入设备 IP）
3. 输入 API 密钥，点击提交

添加成功后自动出现的实体：

| 实体类型 | 数量 | 说明 |
|:---------|:----:|:-----|
| 风扇 | 4 个 | 支持开关和 1-100% 调速 |
| 温度传感器 | 4 个 | 温度 A/B/C/D（v2.0，需接 DS18B20） |
| 转速传感器 | 4 个 | 单位 RPM |
| 蓝牙代理 | 1 个 | BLE Proxy 节点 |
| 诊断实体 | 若干 | 运行时间、Wi-Fi 信号、IP、固件版本等 |

### 4. Web 界面控制

浏览器直接访问 `http://[设备IP]` 即可打开 Web 控制面板，无需 Home Assistant：
- 查看 4 路风扇实时状态
- 滑块独立调节每路风速（1-100%）
- 查看设备运行信息

### 5. 配置 v2.0 温度控制（DS18B20 版本）

> 此步骤适用于 **v2.0 DS18B20 / DS18B20+雷达**固件。如不使用 DS18B20 探头，可通过 [Home Assistant 自动化](#home-assistant-自动化配置)实现温度联动调速。

#### DS18B20 接线

DS18B20 采用 3 线制连接，接口为板载 **GPIO14**（3PIN 排针）：

| DS18B20 引脚 | 连接位置 |
|:------------:|:--------:|
| 红色（VCC） | 3.3V 或 5V |
| 黑色（GND） | GND |
| 黄色（DATA） | GPIO14（板载已集成上拉电阻） |

在 GPIO14 总线上可并联最多 **4 个 DS18B20**，系统自动识别并命名为 **温度 A / B / C / D**。

#### 配置温度绑定

进入 HA → **设置** → **设备与服务** → **ESP32 PWM 22810**，配置每个风扇的参数：

| 参数 | 说明 | 默认值 |
|:-----|:-----|:------:|
| 启控温度 T-Min | 低于或等于此温度，风扇断电完全关停 | 30°C |
| 满载温度 T-Max | 高于此温度，风扇以最高风速运行 | 50°C |
| 最低风速 F-Min | 风扇最低转速百分比 | 0% |
| 最高风速 F-Max | 风扇最高转速百分比 | 100% |
| 温度源绑定 Src | 该风扇绑定的温度传感器 | - |

**工作逻辑**：

```
温度 ≤ 启控温度  →  断电完全关停风扇
启控温度 < 温度 < 满载温度  →  线性比例调速
温度 ≥ 满载温度  →  最高风速运行
```

所有参数支持**掉电保持**，设置一次即可。

---

## HTTP REST API 接口

本项目集成了 Web Server，可通过局域网 HTTP 请求直接控制风扇或获取传感器数据。

> ⚠️ 控制类命令（打开/关闭/调速）使用 **POST**，状态获取使用 **GET**。
> URL 中中文名需进行 URL 编码（空格 → `%20`，中文 → UTF-8 编码）。

### entity_id 对照

ESPHome 2026.6.4 中 `object_id` 不被大部分组件支持，entity_id 由 `name` 自动转换。

| 实体显示名 | entity_id | URL 路径 |
|:-----------|:----------|:---------|
| 风扇 1 | `fan.风扇_1` | `/fan/%E9%A3%8E%E6%89%87_1` |
| 风扇 1 转速 | `sensor.风扇_1_转速` | `/sensor/%E9%A3%8E%E6%89%87_1_%E8%BD%AC%E9%80%9F` |

> **提示**：由于 entity_id 包含中文，推荐通过 Home Assistant 的 `fan.set_percentage` 服务调用，或在 Python 中使用 `urllib.parse.quote()` 自动编码。

### Python 调用示例

```python
import requests
from urllib.parse import quote

base = "http://10.0.20.83"

# 开启 2 号风扇并调整至 50% 风速
requests.post(f"{base}/fan/{quote('风扇 2')}/turn_on", params={"speed_level": 50})

# 关闭 2 号风扇
requests.post(f"{base}/fan/{quote('风扇 2')}/turn_off")

# 获取 1 号风扇当前转速
response = requests.get(f"{base}/sensor/{quote('风扇 1 转速')}")
if response.status_code == 200:
    print("当前转速:", response.json()['value'])
```

---

## Home Assistant 自动化配置

> **v2.0 用户**：DS18B20 版本已内置本地温度控制功能，但同样可以使用以下自动化方式。此配置适用于所有版本，尤其适合 v1.0 用户或需要通过 HA 端获取 CPU 温度、环境温湿度等非 DS18B20 温度源的场景。

### 配置步骤

1. 打开 Home Assistant → **自动化与场景** → **创建自动化**
2. 点击右上角 **更多** → **YAML 编辑**
3. 粘贴下方代码，**修改实体 ID** 后保存

### YAML 模板

```yaml
alias: "通用智能风扇线性调速"
description: "根据温度传感器数值线性控制风扇 PWM 占空比"
mode: restart

trigger:
  - platform: state
    entity_id: sensor.nas_temperature_x86_pkg_temp  # 【需修改】

condition:
  - condition: template
    value_template: "{{ is_number(states('sensor.nas_temperature_x86_pkg_temp')) }}"  # 【需修改】

action:
  - service: fan.set_percentage
    target:
      entity_id: fan.fan_1  # 【需修改】
    data:
      percentage: >
        {% set current_temp = states('sensor.nas_temperature_x86_pkg_temp') | float(0) %}  {# 【需修改】 #}
        {% set t_min = 30 %}   {# 起控温度 #}
        {% set t_max = 50 %}   {# 满载温度 #}
        {% set f_min = 0 %}    {# 最低风速 % #}
        {% set f_max = 100 %}  {# 最高风速 % #}
        {% if current_temp <= t_min %}
          {{ f_min }}
        {% elif current_temp >= t_max %}
          {{ f_max }}
        {% else %}
          {% set result = ((current_temp - t_min) * (f_max - f_min) / (t_max - t_min) + f_min) %}
          {{ result | round(0) | int }}
        {% endif %}
```

### 温度与风速关系图

![温度与风速关系](./docs/images/diagrams/speed-chart.png)

### 支持的常见温度源

| 温度来源 | 获取方式 | 示例实体 ID |
|:---------|:---------|:-----------|
| 电脑/服务器 CPU 温度 | Glances 集成 | `sensor.nas_temperature_x86_pkg_temp` |
| 温湿度传感器 | Zigbee2MQTT / ZHA | `sensor.temperature_humidity_sensor_temperature` |
| 空调/暖气温度 | 智能空调集成 | `climate.living_air_conditioner` |
| 群晖 NAS 温度 | Synology DSM 集成 | `sensor.synology_disk_1_temperature` |
| 其他 ESPHome 设备 | ESPHome 集成 | 自定义 |

---

## 交流群

**不再维护群二维码**

## 请作者喝杯咖啡

<div style="text-align: center;">
  <table>
    <tr>
      <td width="50%" style="padding: 10px;">
        <img src="./docs/images/donations/wechat.jpg" width="220" alt="微信打赏"/>
        <p><small>微信</small></p>
      </td>
      <td width="50%" style="padding: 10px;">
        <img src="./docs/images/donations/alipay.jpg" width="220" alt="支付宝打赏"/>
        <p><small>支付宝</small></p>
      </td>
    </tr>
  </table>
</div>

## 开源许可证

本项目采用 [MIT License](./LICENSE) 开源许可证。
