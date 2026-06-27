# HomeAssistant-PWM-Fan-Controlx4

## 项目简介

 HomeAssistant-PWM-Fan-Controlx4 是一个基于 ESPHome 的 PWM 风扇控制器项目。该控制器支持接入 Home Assistant，实现 4 路风扇的独立调速与智能联动控制。

## 更新日志

### v2.0 [最新版本]
- **🌡️ 新增内置温度控制功能**：集成 DS18B20 温度传感器支持，无需 Home Assistant 自动化即可实现温度驱动的风扇自动调速
- **📊 新增可配置控制参数**：每个风扇支持独立配置启控温度、满载温度、最低/最高风速等参数，支持掉电保持
- **🔗 新增温度源绑定功能**：每个风扇可选择绑定任意一个温度传感器，灵活匹配不同散热需求
- **🎯 新增 24GHz 毫米波雷达版本**：集成 LD2402G 雷达传感器，支持人体存在检测和距离监测
- **🛡️ 新增雷达抗干扰算法**：动态过滤门限、静态干扰排除、固定伪目标识别，提升检测准确性
- **⚙️ 新增雷达动态调参**：支持在 Home Assistant 中实时调节雷达检测范围和灵敏度
- **📦 新增 v2.0 硬件设计**：更新 PCB 布局，新增 3D 打印外壳模型（STL/STEP），优化结构设计与散热风道

### v1.0
- **✨ 新增 Web 界面控制功能**：集成 `web_server` 组件，支持在局域网内通过浏览器（输入设备 IP）直接对 4 路风扇进行可视化开关与 1-100% 滑块调速，并开放了标准的 HTTP REST API 控制接口。
- **🔍 新增诊断实体**：引入 `uptime`、`wifi_signal`、`wifi_info` 及 `version` 平台。在 Home Assistant 中可自动归类生成设备运行时间、Wi-Fi 信号强度、局域网 IP 地址以及 ESPHome 固件版本等诊断型实体，方便日常维护与状态监控。

## 主要功能

- 通过 ESPHome 集成 HomeAssistant 控制
- **支持 Web 网页端/HTTP API 直接控制与百分比调速**
- 支持 4 路风扇独立 PWM 调速及实时转速显示
- **内置完善的硬件与系统诊断实体**（在线时间、信号强度、IP等）
- 可通过 HomeAssistant 自动化联动温湿度传感器，实现环境温度/湿度驱动风速调节
- 可通过 SSH 读取设备 CPU 温度，并结合 HomeAssistant 自动化实现风速控制

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


## 硬件文件

### v2.0 硬件（推荐）

提供完整的硬件设计文件，包含 PCB 设计与 3D 打印外壳。

#### PCB 设计文件
- [📄 Gerber 文件](./hardware/v2.0/pcb/gerber.zip) — 可直接发板厂打样
- [📊 BOM 清单](./hardware/v2.0/pcb/bom.xlsx) — 物料清单
- [🔧 工程文件](./hardware/v2.0/pcb/project.epro2) — 立创 EDA 专业版工程

#### 3D 打印外壳
- [🏠 外壳主体](./hardware/v2.0/3d-models/print/case.STEP) — STEP 格式 3D 模型
- [🔝 上盖](./hardware/v2.0/3d-models/print/top-cover.STEP) — STEP 格式 3D 模型

### v1.0 硬件
- [📄 Gerber 文件](./hardware/v1.0/pcb/gerber.zip)
- [📊 BOM 清单](./hardware/v1.0/pcb/bom.xlsx)
- [🔧 工程文件](./hardware/v1.0/pcb/project.epro2)
- [🏠 外壳主体](./hardware/v1.0/3d-models/print/case.step)
- [🔝 上盖](./hardware/v1.0/3d-models/print/top-cover.step)

> **注意**：v2.0 硬件与 v1.0 固件兼容，v2.0 外壳也兼容 v1.0 主板。

## 控制器硬件实现原理

本控制器的核心硬件设计如下：

- 使用 `TPS22810DBVR` 实现风扇电源控制。
  - 该芯片可直接切断风扇电源，从而有效解决风扇无法完全停转的问题。
- 12V 转 3.3V 电源采用 `TPS5430DDAR` DC-DC 降压芯片+`AMS1117-3.3` 线性稳压器先降至5V再降至3.3V。
  - 该方案效率高、发热低且有效降低为MCU供电的纹波。
- 板载 `CH340C` USB 转串口芯片。
  - 只需通过 Type-C 接口连接电脑即可直接烧录固件。

## IO 接口说明

| 风扇 | PWM 输出 | Tach 输入 | 电源管理 |
| ---- | -------- | --------- | -------- |
| Fan1 | GPIO16   | GPIO32    | GPIO21   |
| Fan2 | GPIO17   | GPIO33    | GPIO22   |
| Fan3 | GPIO18   | GPIO25    | GPIO23   |
| Fan4 | GPIO19   | GPIO26    | GPIO13   |

**注意**：v2.0 版本额外占用以下 IO 接口：
- **GPIO14**：DS18B20 温度传感器 1-Wire 接口
- **GPIO5**：LD2402G 雷达 UART TX（仅雷达版本）
- **GPIO4**：LD2402G 雷达 UART RX（仅雷达版本）

## 固件版本说明

### v1.0 固件

#### 双核版本
- **文件路径**：`firmware/v1.0/dual-core/esp32-pwm-22810.yaml`
- **特点**：
  - 使用 ESP32 双核运行，性能更强
  - 基础 4 路风扇控制功能
  - Web 界面控制和 HTTP API
  - 完整的诊断实体（运行时间、Wi-Fi 信号等）
- **适用场景**：需要更高性能的复杂应用场景
- **预编译固件**：
  - `firmware.bin` - 标准固件
  - `firmware.factory.bin` - 工厂固件
  - `firmware.ota.bin` - OTA 升级固件

#### 单核版本
- **文件路径**：`firmware/v1.0/single-core/esp32-pwm-22810.yaml`
- **特点**：
  - 强制单核运行（`CONFIG_FREERTOS_UNICORE: "y"`）
  - 功耗更低，适合长期运行
  - 功能与双核版本完全一致
- **适用场景**：对功耗敏感的应用或特定兼容性需求
- **预编译固件**：
  - `firmware.bin` - 标准固件
  - `firmware.factory.bin` - 工厂固件
  - `firmware.ota.bin` - OTA 升级固件

### v2.0 固件

#### DS18B20 温度控制版本
- **文件路径**：`firmware/v2.0/single-core/ds18b20/config.yaml`
- **主要特性**：
  - **内置温度控制**：无需 Home Assistant 自动化即可实现温度驱动的自动调速
  - **4 路温度传感器**：支持最多 4 个 DS18B20 温度传感器（GPIO14 接口）
  - **可配置参数**：每个风扇独立配置启控温度、满载温度、最低/最高风速
  - **温度源绑定**：风扇可选择绑定任意温度传感器，灵活配置散热方案
  - **掉电保持**：所有配置参数支持掉电保存
- **新增实体**：
  - 4 个温度传感器实体（温度 A/B/C/D）
  - 每风扇 4 个可配置参数（启控温度、满载温度、最低风速、最高风速）
  - 每风扇 1 个温度源选择器
- **适用场景**：需要独立温度控制的服务器、NAS、散热系统
- **预编译固件**：
  - `firmware.bin` - 标准固件
  - `firmware.factory.bin` - 工厂固件
  - `firmware.ota.bin` - OTA 升级固件

#### DS18B20 + LD2402G 雷达版本
- **文件路径**：`firmware/v2.0/single-core/ds18b20-radar/config.yaml`
- **主要特性**：
  - 包含 DS18B20 版本的所有功能
  - **24GHz 毫米波雷达**：集成 LD2402G 雷达传感器，支持人体存在检测
  - **距离监测**：实时监测目标距离，单位为米
  - **动态抗干扰算法**：
    - 用户可配置检测范围（0.1m-8.0m）
    - 自动过滤静态干扰和固定伪目标
    - 5秒静态锁定保护机制
  - **动态调参**：支持在 Home Assistant 中实时调节雷达参数
- **新增实体**：
  - 雷达检测到目标（二进制传感器）
  - 雷达目标距离（距离传感器）
  - 雷达最近过滤门限（可调参数，0.0-2.0m）
  - 雷达最远过滤门限（可调参数，0.5-8.0m）
- **雷达接口**：
  - **GPIO5**：雷达 UART TX
  - **GPIO4**：雷达 UART RX
- **适用场景**：智能家居、办公室、机房等需要人体感应的散热控制
- **预编译固件**：
  - `firmware.bin` - 标准固件
  - `firmware.factory.bin` - 工厂固件
  - `firmware.ota.bin` - OTA 升级固件

### 版本选择建议

> **⚠️ 重要提醒**：如果您购买的是本项目作者提供的**成品设备**，该设备采用**单核设计**，**只能刷入单核固件**（v1.0 单核版本或 v2.0 系列版本），请勿刷入双核固件，否则可能导致设备无法正常工作。

| 使用场景 | 推荐版本 | 原因 |
|---------|---------|------|
| 简单风扇控制，已有 HA 自动化 | [v1.0 双核](./firmware/v1.0/dual-core/) / [单核](./firmware/v1.0/single-core/) | 基础功能完备，稳定可靠 |
| 需要独立温度控制，不想配置自动化 | [v2.0 DS18B20](./firmware/v2.0/single-core/ds18b20/) | 内置温度控制，开箱即用 |
| 智能家居，需要人体感应控制 | [v2.0 DS18B20+雷达](./firmware/v2.0/single-core/ds18b20-radar/) | 联动人体存在，智能节能 |
| 长期运行，关注功耗 | [v2.0 单核版本](./firmware/v2.0/single-core/ds18b20/) | 单核运行，功耗更低 |
| 复杂应用，需要高性能 | [v1.0 双核版本](./firmware/v1.0/dual-core/) | 双核性能，处理能力更强 |

### 固件烧录说明

所有版本均提供三种预编译固件：

1. **firmware.bin**：标准固件，用于常规烧录
2. **firmware.factory.bin**：工厂固件，用于完整恢复出厂设置
3. **firmware.ota.bin**：OTA 升级固件，用于在线升级

**烧录方法**：
- 通过 Type-C 接口连接电脑
- 使用 ESPHome 烧录工具或 esptool
- 选择对应版本的 `.bin` 文件进行烧录

**自定义编译**：
如需修改配置，可使用 ESPHome 对应的 `.yaml` 配置文件自行编译。

## 快速上手指南

> 🔑 **API 加密密钥**：`LqGIGJ3qyRc+6X6hsMe5vAms+Jyh2lOMh1FQu8yyuzk=`
> 在将设备添加到 Home Assistant 时需要用到此密钥，请复制保存。

### 第一步：供电与首次启动

控制器提供两种供电方式，请根据场景选择：

#### 方式 A：DC 接口供电（正常运行）✅ 推荐

- 使用 **12V 电源适配器** 通过 **DC 接口** 供电
- 这是设备**正常运行**的供电方式，可同时为 4 路风扇及 ESP32 主控供电
- 建议使用 12V/2A 以上的电源适配器

#### 方式 B：Type-C 接口供电（烧录/调试）

- **Type-C 接口为 5V 输入**，未做 PD 诱骗，仅用于烧录程序或调试
- 使用 USB 数据线连接电脑即可供电，同时可通过板载 `CH340C` 芯片直接烧录固件
- 此方式下**风扇无法工作**（因风扇需要 12V 供电），仅供有开发能力的用户烧录或调试使用

#### 首次启动

- 无论使用哪种方式供电，上电后设备都会自动创建一个名为 `ESP32-Fan-22810` 的 Wi-Fi 热点（无需密码）
- 可用手机或电脑连接该热点进行配网

### 第二步：连接 Wi-Fi 网络

1. 连接设备热点 `ESP32-Fan-22810`
2. 打开浏览器，访问任一地址：
   - `http://192.168.4.1`（热点默认网关）
   - 或 `http://esp32pwm22810.local`
3. 页面会自动弹出 Wi-Fi 配置向导
4. 选择你的家庭/公司 Wi-Fi 并输入密码
5. 设备会自动连接并重启

> 💡 **提示**：你也可以在固件烧录前，在 `config.yaml` 中预先配置好 Wi-Fi 信息（`wifi.ssid` 和 `wifi.password`），这样设备通电后会自动连接。

### 第三步：在 Home Assistant 中添加设备

设备连接成功后，有两种方式接入 Home Assistant：

#### 方式 A：自动发现（推荐）

1. 确保 Home Assistant 已安装 **ESPHome 集成**
2. 进入 Home Assistant → **设置** → **设备与服务** → **添加集成**
3. 搜索并选择 **ESPHome**
4. 系统会自动扫描到名为 `ESP32 PWM 22810` 的设备
5. 输入 API 密钥（密钥见上方「快速上手指南」区域）
6. 点击提交完成添加

#### 方式 B：手动添加

1. 在 Home Assistant 中进入 **设置** → **设备与服务** → **添加集成** → **ESPHome**
2. 手动输入设备 IP 地址（可在路由器后台查看，或通过 `http://esp32pwm22810.local` 访问 Web 界面获取）
3. 输入 API 加密密钥
4. 点击提交完成添加

添加成功后，你将看到以下实体自动出现在 Home Assistant 中：

| 实体类型 | 数量 | 说明 |
|---------|:---:|------|
| 🌀 风扇 | 4 个 | 风扇 1~4，支持开关和百分比调速 |
| 🌡️ 温度传感器 | 4 个 | 温度 A/B/C/D（仅 v2.0 固件，接 DS18B20 后显示） |
| 🔄 转速传感器 | 4 个 | 风扇 1~4 转速，单位 RPM |
| 📶 诊断实体 | 若干 | 设备运行时间、Wi-Fi 信号强度、IP 地址、固件版本等 |

### 第四步：通过 Web 界面直接控制

无需 Home Assistant，在浏览器中直接访问设备 IP 即可打开 Web 控制面板：

```
http://[设备IP]
```

在 Web 界面中你可以：
- 查看 4 路风扇的实时状态
- 通过滑块独立调节每路风扇风速（1~100%）
- 查看设备运行信息（在线时间、Wi-Fi 信号等）

### 第五步：配置 v2.0 内置温度控制（DS18B20 版本）

> 本步骤仅适用于 **v2.0 DS18B20 固件** 用户，v1.0 用户请参考下一节的 Home Assistant 自动化配置。

#### 接线 DS18B20 温度探头

DS18B20 采用 **3 线制** 连接，接口位置为板载 **GPIO14**（3PIN 排针）：

| DS18B20 引脚 | 连接位置 |
|:-----------:|:--------:|
| 红色（VCC） | **3.3V** 或 **5V** |
| 黑色（GND） | **GND** |
| 黄色（DATA） | **GPIO14**（PCB 板载已集成上拉电阻，直接连接即可） |

> 💡 **提示**：如果你购买的是成品设备，DS18B20 探头通常已经焊接好接口，直接插入即可。

#### 支持最多 4 个探头

在 GPIO14 总线上可并联最多 **4 个 DS18B20**，系统会自动识别并分别命名为 **温度 A / B / C / D**。

#### 在 Home Assistant 中配置温度绑定

1. 进入 Home Assistant → **设置** → **设备与服务** → **ESP32 PWM 22810** 设备
2. 你会看到以下可配置参数（每个风扇独立）：

| 参数 | 说明 | 默认值 |
|:---|:----|:-----:|
| 启控温度 T-Min | 低于此温度，风扇以最低风速运行 | 30°C |
| 满载温度 T-Max | 高于此温度，风扇以最高风速运行 | 50°C |
| 最低风速 F-Min | 风扇最低转速百分比 | 0% |
| 最高风速 F-Max | 风扇最高转速百分比 | 100% |
| 温度源绑定 Src | 该风扇绑定的温度传感器 | - |

3. **配置步骤**：
   - 将每个风扇的「温度源绑定」设为对应的温度传感器（如风扇 1 → 温度 A）
   - 调节「启控温度」和「满载温度」设定控温范围
   - 调节「最低/最高风速」限制风扇转速区间
   - 所有参数支持**掉电保持**，设置一次即可

#### 工作逻辑

```
温度 ≤ 启控温度  →  最低风速运行（或停转）
启控温度 < 温度 < 满载温度  →  线性比例调速
温度 ≥ 满载温度  →  最高风速运行
```

---

## 获取温度的两种方式

本控制器支持两种方式获取温度，从而实现温度驱动风扇调速：

### 方式一：DS18B20 温度探头（v2.0 内置方案）✅ 推荐

适用于 **v2.0 DS18B20 / DS18B20+雷达固件**，无需在 Home Assistant 中配置任何自动化。

| 特性 | 说明 |
|:---|:----|
| **传感器** | DS18B20 数字温度传感器（精度 ±0.5°C） |
| **数量** | 最多 4 个（温度 A/B/C/D） |
| **接口** | GPIO14（1-Wire 单总线） |
| **控制方式** | 设备内置 PID/线性控制逻辑，独立运行 |
| **优点** | ✅ 不依赖 HA，断网也能正常工作 ✅ 响应迅速 ✅ 配置简单 |

**接线方式**：详见上方「第五步」中的接线说明。

**适用场景**：
- 服务器/机柜内部温度监测
- NAS 硬盘散热
- 3D 打印机仓温控制
- 需要本地独立运行的环境

### 方式二：Home Assistant 自动化方案

适用于 **v1.0 固件** 用户，或需要使用其他温度传感器（如 CPU 温度、环境温湿度传感器等）的场景。

**工作原理**：在 Home Assistant 中创建自动化规则，读取任意温度传感器的数值，根据温度值计算目标风速，然后通过服务调用控制风扇转速。

#### 支持的常见温度源

| 温度来源 | 获取方式 | 示例实体 ID |
|:--------|:--------|:----------|
| 💻 电脑/服务器 CPU 温度 | 通过 Home Assistant 的 Glances 集成 | `sensor.nas_temperature_x86_pkg_temp` |
| 🌡️ 温湿度传感器 | 通过 Zigbee2MQTT / ZHA 接入 | `sensor.temperature_humidity_sensor_temperature` |
| 🌤️ 空调/暖气温度 | 通过智能空调集成 | `climate.living_air_conditioner` |
| 🖥️ 群晖 NAS 温度 | 通过 Synology DSM 集成 | `sensor.synology_disk_1_temperature` |
| 📦 其他 ESPHome 设备 | 通过 ESPHome 集成 | 自定义 |

#### 自动化配置示例

详细配置方法请参考下方的「HomeAssistant 自动化配置」章节，已提供完整的 YAML 自动化模板，根据注释替换实体 ID 即可使用。

---


## HTTP REST API 接口说明

本项目集成了 Web Server，允许用户通过局域网发送 HTTP 请求来直接控制风扇或获取传感器数据。请将下表 URL 中的 `[设备IP]` 替换为控制器的真实局域网 IP，将 `[风扇编号]` 替换为 `1`、`2`、`3` 或 `4`。

> ⚠️ **注意**：
> 1. **控制类命令**（打开、关闭、调速）必须使用 **POST** 方法发送。
> 2. **状态获取命令**（获取转速）必须使用 **GET** 方法发送。
> 3. 由于设备默认采用中文命名且带有空格（例如："风扇 1 转速"），在组装 URL 时需要进行 URL 编码（对照表见下文）。

| 功能描述 | 请求方法 | 通用 API 接口 URL | URL 路径解码后内容 | 参数说明 |
| :--- | :---: | :--- | :--- | :--- |
| **打开风扇** | `POST` | `http://[设备IP]/fan/%E9%A3%8E%E6%89%87%20[风扇编号]/turn_on` | `/fan/风扇 [风扇编号]/turn_on` | 无 |
| **关闭风扇** | `POST` | `http://[设备IP]/fan/%E9%A3%8E%E6%89%87%20[风扇编号]/turn_off` | `/fan/风扇 [风扇编号]/turn_off` | 无 |
| **风扇调速** | `POST` | `http://[设备IP]/fan/%E9%A3%8E%E6%89%87%20[风扇编号]/turn_on?speed_level=[风速百分比]` | `/fan/风扇 [风扇编号]/turn_on?...` | `speed_level`：整数，范围 `1-100` |
| **获取风扇转速** | `GET` | `http://[设备IP]/sensor/%E9%A3%8E%E6%89%87%20[风扇编号]%20%E8%BD%AC%E9%80%9F` | `/sensor/风扇 [风扇编号] 转速` | 无（返回包含转速数值的 JSON） |

*Python 调用示例：*
```python
import requests

# 1. 开启 2 号风扇并调整至 50% 风速 (POST)
requests.post("http://10.0.20.83/fan/风扇 2/turn_on", params={"speed_level": 50})

# 2. 关闭 2 号风扇 (POST)
requests.post("http://10.0.20.83/fan/风扇 2/turn_off")

# 3. 获取 1 号风扇的当前实时转速 (GET)
response = requests.get("http://10.0.20.83/sensor/风扇 1 转速")

# 响应json示例：
# {
#   "name_id": "sensor/风扇 1 转速",
#   "id": "sensor-_______1_______",
#   "value": 1507.5,
#   "state": "1507.50 RPM"
# }

if response.status_code == 200:
    print("当前转速:", response.json()['value'])
```

## HomeAssistant 自动化配置

> **📌 重要提示**：如果您使用的是 **v2.0 固件**（DS18B20 或 DS18B20+雷达版本），设备已内置温度控制功能，**无需配置 HomeAssistant 自动化**即可实现温度驱动的自动调速。您可以直接在 Home Assistant 中调节各个风扇的控制参数。
> 
> 以下自动化配置仅适用于 **v1.0 固件**用户，或需要在 Home Assistant 端实现更复杂控制逻辑的场景。

本项目支持通过 HomeAssistant 自动化实现智能风扇控制。以下示例展示如何配置一个根据温度传感器数值线性调速的自动化。

### 配置步骤

1. 打开 HomeAssistant
2. 进入 **自动化与场景** → **创建自动化** → **创建新的自动化**
3. 点击右上角 **更多** → **YAML 编辑**
4. 将下方的 YAML 代码复制粘贴到编辑器中
5. **修改实体 ID**（详见代码中的注释）
6. 保存自动化

### YAML 自动化配置

```yaml
alias: "通用智能风扇线性调速"
description: "根据温度传感器数值线性控制风扇 PWM 占空比"
mode: restart # 确保每次温度变化都能立即重新计算并覆盖旧任务

trigger:
  - platform: state
    entity_id: sensor.nas_temperature_x86_pkg_temp  # 【需修改】改为你自己的温度传感器实体 ID
    # 如果希望风扇不要过于灵敏，可以取消下面这一行的注释
    # for: "00:00:05" 

condition:
  # 检查传感器状态是否为有效数字，避免设备离线时自动化报错
  - condition: template
    value_template: "{{ is_number(states('sensor.nas_temperature_x86_pkg_temp')) }}" # 【需修改】这里的 ID 也要同步

action:
  - service: fan.set_percentage
    target:
      entity_id: fan.esp32_pwm_22810_feng_shan_1 # 【需修改】改为你自己的风扇实体 ID
    data:
      percentage: >
        {# 读取传感器数值 #}
        {% set current_temp = states('sensor.nas_temperature_x86_pkg_temp') | float(0) %} {# 【需修改】这里的 ID 也要同步 #}
        
        {# --- 自定义配置区域 --- #}
        {% set t_min = 30 %}   {# 起控温度：低于此温度风速为 f_min #}
        {% set t_max = 50 %}   {# 满载温度：高于此温度风速为 f_max #}
        {% set f_min = 0 %}    {# 最低风速百分比 #}
        {% set f_max = 100 %}  {# 最高风速百分比 #}
        {# --------------------- #}
        
        {% if current_temp <= t_min %}
          {{ f_min }}
        {% elif current_temp >= t_max %}
          {{ f_max }}
        {% else %}
          {# 线性计算公式 #}
          {% set result = ((current_temp - t_min) * (f_max - f_min) / (t_max - t_min) + f_min) %}
          {{ result | round(0) | int }}
        {% endif %}
```

### 温度与风速关系图

若未修改上述配置中的最低/最高温度和风速参数（即保持默认值：最低温度 30°C、最高温度 50°C、最低风速 0%、最高风速 100%），温度与风速的线性关系如下图所示：

![温度与风速关系](./docs/images/diagrams/speed-chart.png)

### 配置说明

- **起控温度（t_min）**：低于此温度时，风扇保持最低风速
- **满载温度（t_max）**：高于此温度时，风扇保持最高风速
- **最低风速（f_min）**：建议设为 0%，此时风扇完全停转
- **最高风速（f_max）**：建议设为 100%，风扇全速运转
- **线性调速**：在最低和最高温度之间，风扇风速将根据当前温度线性调节

## 交流群

厚礼蟹🦀 微信群二维码有效期只有7天 每隔7天更新一次好麻烦啊 偷个懒直接删掉二维码吧 这样也不用更新了 俺真是太聪明🌶 

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

## 二创项目

欢迎大家对本项目的硬件、软件甚至外壳进行二创和优化。如果你希望将自己的 Fork 项目展示在本项目中，请先联系我并提交你的修改说明。

审核通过后，你的项目将被展示在下方区域。

| 项目地址 | 项目说明 |
| ---- | -------- | 
| None | None   |

## 开源许可证

本项目采用 [MIT License](./LICENSE) 开源许可证。

有关详细信息，请参阅 [LICENSE](./LICENSE) 文件。