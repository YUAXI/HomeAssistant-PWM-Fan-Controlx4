# 固件版本与编译

[← 首页](Home) · **中文** · [English](Firmware-EN)

## 版本矩阵

| 固件 | 处理器 | 4 路风扇 | 转速 | 温度闭环 | 雷达 | BLE Proxy | 配置文件 |
|:-----|:------:|:--------:|:----:|:--------:|:----:|:---------:|:---------|
| v1.0 双核 | 双核 | ✅ | ✅ | - | - | ✅ | `firmware/v1.0/dual-core/config.yaml` |
| v1.0 单核 | 单核 | ✅ | ✅ | - | - | ✅ | `firmware/v1.0/single-core/config.yaml` |
| v2.0 Basic | 单核 | ✅ | ✅ | - | - | ✅ | `firmware/v2.0/single-core/basic/config.yaml` |
| v2.0 DS18B20 | 单核 | ✅ | ✅ | ✅ | - | ✅ | `firmware/v2.0/single-core/ds18b20/config.yaml` |
| v2.0 + 雷达 | 单核 | ✅ | ✅ | ✅ | ✅ | ✅ | `firmware/v2.0/single-core/ds18b20-radar/config.yaml` |

所有版本共享的配置骨架：

| 配置项 | 值 | 影响 |
|:-------|:---|:-----|
| `esp32.board` | `esp32dev` | ESP32-WROOM-32 |
| `esp32.variant` | `ESP32` | — |
| `esp32.framework` | `esp-idf` | 非 Arduino |
| `CONFIG_FREERTOS_UNICORE` | 单核版本为 `y` | 只启用 1 个核心 |
| `CONFIG_ESP_SYSTEM_PANIC_PRINT_REBOOT` | `y` | 崩溃后自动重启 |
| `logger.level` | `INFO` | 串口/网页日志级别 |
| `web_server.port` | `80` | Web 面板与 REST API |
| `bluetooth_proxy.active` | `true` | 主动连接 BLE 设备 |

## 怎么判断该刷哪个

```text
拿到设备
  ├─ 能确认是双核 ESP32 且需要更高性能 ──→ v1.0 双核
  ├─ 不确定单核/双核 ────────────────────→ 单核固件（v1.0 单核 或 任意 v2.0）
  ├─ v2.0 硬件但没有温度/雷达需求 ───────→ v2.0 Basic
  ├─ 需要脱离 HA 独立控温 ───────────────→ v2.0 DS18B20
  └─ 需要人体存在检测 ───────────────────→ v2.0 DS18B20 + 雷达
```

> **为什么单核固件更安全**：`CONFIG_FREERTOS_UNICORE: "y"` 只是让 FreeRTOS 只调度一个核心，双核 ESP32 上依然可以正常运行；反过来，双核固件在只能单核运行的设备上会启动失败。**所以拿不准时选单核。**
>
> **成品设备通常是单核设计**，只能刷 `v1.0 单核` 或任意 `v2.0` 固件。刷入 `v1.0 双核` 固件会导致设备无法启动，只能重新用 USB 刷回。

v1.0 单核与 v2.0 Basic 的配置文件内容完全一致（仅目录不同），区别只在硬件版本归属；v2.0 Basic 更适合作为 v2.0 板卡的默认选择。

## Release 产物

固件由 GitHub Actions 自动编译，发布在 [Releases](https://github.com/YUAXI/HomeAssistant-PWM-Fan-Controlx4/releases)，tag 为构建日期（如 `2026.10.14`）。每个 Release 包含 5 个版本 × 3 类文件：

| 文件后缀 | 内容 | 用在哪 |
|:---------|:-----|:-------|
| `*.firmware.bin` | 仅应用分区 | OTA 升级、`esptool` 写 `0x10000` |
| `*.firmware.factory.bin` | 引导程序 + 分区表 + 应用 | 首次刷写 / 救砖，写 `0x0` |
| `*.firmware.ota.bin` | OTA 专用镜像 | ESPHome Dashboard / `esphome upload` |

文件名形如 `v2.0-ds18b20.v2.0-ds18b20.firmware.factory.bin`（`<版本名>.<ESPHome 产物名>.bin`）。

| Release 版本名 | 配置文件 |
|:---------------|:---------|
| `v1.0-dual-core` | `firmware/v1.0/dual-core/config.yaml` |
| `v1.0-single-core` | `firmware/v1.0/single-core/config.yaml` |
| `v2.0-basic` | `firmware/v2.0/single-core/basic/config.yaml` |
| `v2.0-ds18b20` | `firmware/v2.0/single-core/ds18b20/config.yaml` |
| `v2.0-ds18b20-radar` | `firmware/v2.0/single-core/ds18b20-radar/config.yaml` |

## 自定义编译

改 Wi-Fi、改实体名、改 API 密钥都需要自己编译。推荐流程：

```bash
pip install esphome
esphome config firmware/v2.0/single-core/basic/config.yaml   # 先校验语法
esphome compile firmware/v2.0/single-core/basic/config.yaml
esphome upload  firmware/v2.0/single-core/basic/config.yaml
```

### 预置 Wi-Fi（跳过配网）

```yaml
wifi:
  ssid: "your-ssid"
  password: "your-password"
  ap:                       # 保留热点作为兜底
    ssid: "ESP32-Fan-22810"
    password: ""
```

### 修改 API 密钥与 OTA 密码

```yaml
api:
  encryption:
    key: "改成你自己的 32 字节 base64 密钥"
ota:
  - platform: esphome
    password: "改成你自己的密码"
```

> 改 API 密钥后，HA 中的旧条目会认证失败，需要删除设备重新添加。生成密钥：`openssl rand -base64 32`。

### 修改实体名称

```yaml
fan:
  - platform: speed
    output: fan1_pwm
    name: "机柜风扇"      # 改这里
```

注意连锁影响：

1. HA 中 `entity_id` 会随之变化（如 `fan.xxx_ji_gui_feng_shan`），引用它的自动化/仪表板需要同步更新；
2. HTTP API 的 URL 路径也随之变化（见 [HTTP API](HTTP-API)）；
3. 带 `name_add_mac_suffix: true` 时设备名后缀不受影响，多设备仍不冲突。

### 改成每台设备独立命名

```yaml
substitutions:
  device_name: fanctrl-01

esphome:
  name: ${device_name}
  name_add_mac_suffix: false
```

中文命名可读性更好，但会让 URL 需要编码；如果打算大量用 HTTP API，建议改成 ASCII 名称（如 `fan 1`）。开启后缀时 `name` 最长 24 字符（ESPHome 主机名上限 31，后缀占 7），`esp32pwm22810` 远低于限制。

### 加自己的传感器

以 I²C 温湿度为例，加在任意位置即可（会与风扇实体并列出现在 HA）：

```yaml
i2c:
  sda: GPIO27
  scl: GPIO2      # GPIO2 是启动脚，接线时确保上电不被拉低

sensor:
  - platform: sht3xd
    temperature:
      name: "机柜温度"
    humidity:
      name: "机柜湿度"
    update_interval: 30s
```

> 动手前先确认目标引脚没被风扇占用：GPIO16–19（PWM）、GPIO32/33/25/26（转速）、GPIO21/22/23/13（电源开关）、GPIO14（1-Wire）、GPIO4/5（雷达串口）。完整表见 [硬件资料](Hardware#gpio-分配)。

## CI 构建流程

`.github/workflows/build.yml`：

| 阶段 | 行为 |
|:-----|:-----|
| 触发 | push 到 `master`，或在 Actions 页面 `workflow_dispatch` 手动触发 |
| 矩阵 | 5 个配置并行编译，`fail-fast: false`（互不影响） |
| 环境 | `ubuntu-latest` + Python 3.11 + `pip install esphome`（始终最新版） |
| 缓存 | `~/.esphome`，key 取 `firmware/**/config.yaml` 的哈希 |
| 编译 | `esphome compile <config>` |
| 收集 | 从 `<配置目录>/.esphome` 里找 `firmware*.bin`，重命名为 `<版本名>.<原名>` |
| 发布 | `softprops/action-gh-release@v2`，tag 为当天日期，附带 5 个版本的 bin |

由此带来的两个注意点：

- CI 用最新版 ESPHome，**上游大版本升级可能导致编译失败**；本地排错时先 `pip install -U esphome` 复现。
- Release tag 是日期，同一天多次触发会更新同一个 Release（同名 tag），属于预期行为。

## 升级与回滚

| 操作 | 做法 |
|:-----|:-----|
| HA 内升级 | ESPHome 集成 → 设备 → 三个点 → 更新（仅当设备由 HA 托管编译时可用） |
| CLI 升级 | `esphome upload <config> --device <IP>` |
| Web 面板升级 | 默认配置的 `web_server` 不提供 OTA，请用上面两种方式 |
| 回滚 | 下载旧 Release 的 `.firmware.ota.bin` 重新 upload 即可；跨硬件版本的回滚没有意义 |
| 救砖 | USB + `esptool` 写 `.firmware.factory.bin` 到 `0x0`，必要时按住 BOOT 进下载模式 |

升级前建议：

1. 确认新固件与硬件版本匹配（尤其双核/单核）；
2. 记录当前 `T-Min` / `T-Max` 等参数（`restore_value` 存在设备 NVS 中，正常 OTA 会保留，但换分区表的刷写可能清零）；
3. 避免在无人值守时远程 OTA——断电会需要现场救砖。
