# 固件版本与编译

[← 首页](Home) · **中文** · [English](Firmware-EN)

## 版本矩阵

| 固件 | 处理器 | 4 路风扇 | 转速 | 温度闭环 | 雷达 | BLE Proxy | 配置文件（中文版） |
|:-----|:------:|:--------:|:----:|:--------:|:----:|:---------:|:---------|
| v2.0 Basic | 双核 | ✅ | ✅ | - | - | ✅ | `firmware/zh/v2.0/dual-core/basic/config.yaml` |
| v2.0 DS18B20 | 双核 | ✅ | ✅ | ✅ | - | ✅ | `firmware/zh/v2.0/dual-core/ds18b20/config.yaml` |
| v2.0 + 雷达 | 双核 | ✅ | ✅ | ✅ | ✅ | ✅ | `firmware/zh/v2.0/dual-core/ds18b20-radar/config.yaml` |

> **2026-11-12 之后售卖的成品全部是双核。** 因此上表 3 个当前版本都是**双核构建**：不设置 `CONFIG_FREERTOS_UNICORE`，FreeRTOS 两个核心都参与调度。
>
> **整个 v1.0 系列已归档**；早于 2026-11-12 出货的**单核板**也无法启动双核固件（表现为上电后不断重启、串口反复打印 `Guru Meditation` 或直接卡住），需要改用[归档的构建](#归档的构建)自行编译。反方向没有限制：**双核板可以运行归档单核固件**，只是闲置一个核心。

> 每个版本都有中英两套配置：中文版在 `firmware/zh/`（实体名 `风扇 1`、`温度 A`、`设备运行时间`…），英文版在 `firmware/en/`（实体名 `Fan 1`、`Temp A`、`Uptime`…）。**英文版是主要推荐构建**，也是 `readme.md` 主文档默认描述的对象；中文版保留最初的实体命名。两者引脚、逻辑、节点名（`esp32pwm22810`）与 API 密钥完全一致，仅实体名不同——上表列出中文版路径，把 `zh/` 换成 `en/` 即为英文版配置。

所有版本共享的配置骨架：

| 配置项 | 值 | 影响 |
|:-------|:---|:-----|
| `esp32.board` | `esp32dev` | ESP32-WROOM-32 |
| `esp32.variant` | `ESP32` | — |
| `esp32.framework` | `esp-idf` | 非 Arduino |
| `CONFIG_FREERTOS_UNICORE` | 双核构建**不设置**；归档单核构建为 `y` | 只让 FreeRTOS 调度 1 个核心 |
| `CONFIG_ESP_SYSTEM_PANIC_PRINT_REBOOT` | `y` | 崩溃后自动重启 |
| `logger.level` | `INFO` | 串口/网页日志级别 |
| `web_server.port` | `80` | Web 面板与 REST API |
| `bluetooth_proxy.active` | `true` | 主动连接 BLE 设备 |

## 怎么判断该刷哪个

```text
拿到设备
  ├─ 2026-11-12 之后购买（当前成品）──────→ 双核 v2.0：Basic / DS18B20 / 雷达
  ├─ v2.0 硬件但没有温度/雷达需求 ───────→ v2.0 Basic（双核）
  ├─ 需要脱离 HA 独立控温 ───────────────→ v2.0 DS18B20（双核）
  ├─ 需要人体存在检测 ───────────────────→ v2.0 DS18B20 + 雷达（双核）
  ├─ v1.0 板卡（任意变体，已归档）────────→ 归档的 v1.0 构建（自行编译）
  └─ 更早购买的老设备（单核板）──────────→ 归档单核构建（自行编译）
```

> **默认答案是双核 v2.0。** 2026-11-12 之后出货的成品全部为双核板，直接刷上表任意一个当前版本即可。
>
> **v1.0 与单核只针对老硬件。** v1.0 板卡请用 `firmware/*/archive/v1.0/` 下的归档构建；单核板请用 `firmware/*/archive/v2.0/single-core/` 下的归档单核构建（下一节）。双核板则两种都能跑，没有必要退回单核固件——那会浪费一个核心。

同一语言内，**归档的 v1.0 单核**与**归档的 v2.0 单核 Basic** 配置文件内容完全一致（仅目录不同），区别只在硬件版本归属。中英两套配置之间则只差实体名、选项文字与注释。

## 归档的构建

整个 v1.0 系列与单核配置已归档：**CI 不再编译、Release 不再发布**，只保留源码供老设备使用，需要时自行编译。

| 归档固件 | 中文配置 | 英文配置 |
|:---------|:---------|:---------|
| v1.0 双核 | `firmware/zh/archive/v1.0/dual-core/config.yaml` | `firmware/en/archive/v1.0/dual-core/config.yaml` |
| v1.0 单核 | `firmware/zh/archive/v1.0/single-core/config.yaml` | `firmware/en/archive/v1.0/single-core/config.yaml` |
| v2.0 Basic（单核） | `firmware/zh/archive/v2.0/single-core/basic/config.yaml` | `firmware/en/archive/v2.0/single-core/basic/config.yaml` |
| v2.0 DS18B20（单核） | `firmware/zh/archive/v2.0/single-core/ds18b20/config.yaml` | `firmware/en/archive/v2.0/single-core/ds18b20/config.yaml` |
| v2.0 DS18B20 + 雷达（单核） | `firmware/zh/archive/v2.0/single-core/ds18b20-radar/config.yaml` | `firmware/en/archive/v2.0/single-core/ds18b20-radar/config.yaml` |

```bash
# 老设备才需要：自己编译归档构建（默认英文版，中文版换 zh/）
esphome compile firmware/en/archive/v2.0/single-core/ds18b20/config.yaml   # 单核老设备
esphome compile firmware/en/archive/v1.0/dual-core/config.yaml            # v1.0 板卡
```

> 对单核 v2.0 构建，与当前双核构建的唯一区别是 `CONFIG_FREERTOS_UNICORE: "y"`；v1.0 构建则是另一代配置（无温度/雷达接口）。它们不在 Release 里，所以**下载不到预编译产物**，只能用上面的命令自行编译，或回退到历史上包含旧产物的旧 Release。
>
> 反过来，新买的双核板**不需要**归档构建；刷归档单核固件虽然能启动，但会闲置一个核心。

## Release 产物

固件由 GitHub Actions 自动编译，发布在 [Releases](https://github.com/YUAXI/HomeAssistant-PWM-Fan-Controlx4/releases)，tag 为构建日期（如 `2026.10.14`）。每个 Release 包含 **6 个构建（3 个当前版本 × 2 种语言）**，每个构建各有 3 类文件（共 **18 个 bin**）：英文版（`-en`）是主要推荐构建，中文版（`-zh`）保留原始的中文实体名。**不再发布 v1.0 与 single-core 产物**（见 [归档的构建](#归档的构建)）。

| 文件后缀 | 内容 | 用在哪 |
|:---------|:-----|:-------|
| `*.firmware.bin` | 仅应用分区 | OTA 升级、`esptool` 写 `0x10000` |
| `*.firmware.factory.bin` | 引导程序 + 分区表 + 应用 | 首次刷写 / 救砖，写 `0x0` |
| `*.firmware.ota.bin` | OTA 专用镜像 | ESPHome Dashboard / `esphome upload` |

文件名形如 `v2.0-ds18b20-zh.firmware.factory.bin`（`<构建名>.firmware*.bin`，构建名见下表）：

| 版本 | Release 产物（en / zh） | 配置文件（en 主推 / zh） |
|:-----|:------------------------|:-------------------------|
| v2.0 Basic | `v2.0-basic-en`<br>`v2.0-basic-zh` | `firmware/en/v2.0/dual-core/basic/config.yaml`<br>`firmware/zh/v2.0/dual-core/basic/config.yaml` |
| v2.0 DS18B20 | `v2.0-ds18b20-en`<br>`v2.0-ds18b20-zh` | `firmware/en/v2.0/dual-core/ds18b20/config.yaml`<br>`firmware/zh/v2.0/dual-core/ds18b20/config.yaml` |
| v2.0 DS18B20 + 雷达 | `v2.0-ds18b20-radar-en`<br>`v2.0-ds18b20-radar-zh` | `firmware/en/v2.0/dual-core/ds18b20-radar/config.yaml`<br>`firmware/zh/v2.0/dual-core/ds18b20-radar/config.yaml` |

> 同一个版本的中英构建除实体名外完全一致，可以直接互相 OTA 覆盖；但换语言后 HA 里的实体名（以及 `entity_id`、HTTP API 路径）会随之变化，需要按新实体名重新配置。

## 自定义编译

改 Wi-Fi、改实体名、改 API 密钥都需要自己编译。推荐流程：

```bash
pip install esphome

# 中文版（实体名 风扇 1 / 温度 A / 设备运行时间），以 v2.0 DS18B20 双核为例
esphome config  firmware/zh/v2.0/dual-core/ds18b20/config.yaml   # 先校验语法
esphome compile firmware/zh/v2.0/dual-core/ds18b20/config.yaml
esphome upload  firmware/zh/v2.0/dual-core/ds18b20/config.yaml

# 最精简的变体：v2.0 Basic（双核）
esphome compile firmware/zh/v2.0/dual-core/basic/config.yaml

# 英文版（主推，实体名 Fan 1 / Temp A / Uptime）
esphome compile firmware/en/v2.0/dual-core/ds18b20/config.yaml
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

> 英文版配置（`firmware/en/`）里的 `name` 默认就是英文（`Fan 1`、`Fan 1 RPM`…），改法完全相同；改名同样会改变 `entity_id` 与 REST 路径。

### 改成每台设备独立命名

```yaml
substitutions:
  device_name: fanctrl-01

esphome:
  name: ${device_name}
  name_add_mac_suffix: false
```

中文命名可读性更好，但会让 URL 需要编码；如果打算大量用 HTTP API，建议直接用英文版配置（实体名已是 `Fan 1` 这类 ASCII 名称），或自己把 `name` 改成 ASCII 名称。开启后缀时 `name` 最长 24 字符（ESPHome 主机名上限 31，后缀占 7），`esp32pwm22810` 远低于限制。

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
| 矩阵 | 6 个配置（3 个当前版本 × 2 种语言）并行编译，`fail-fast: false`（互不影响）；归档配置（v1.0 与单核）不在矩阵中 |
| 环境 | `ubuntu-latest` + Python 3.11 + `pip install esphome`（始终最新版） |
| 缓存 | `~/.esphome`，key 取 `firmware/**/config.yaml` 的哈希 |
| 编译 | `esphome compile <config>` |
| 收集 | 从 `<配置目录>/.esphome` 里找 `firmware*.bin`，重命名为 `<构建名>.<原名>`（如 `v2.0-basic-zh.firmware.bin`） |
| 校验 | 发布前检查 3 个 v2.0 变体的 `-en` 与 `-zh` 镜像是否齐全，缺失则失败 |
| 发布 | `softprops/action-gh-release@v2`，tag 为当天日期，附带 6 个构建（`-en` / `-zh`）的 bin |

矩阵中的 6 个配置：

| 构建名 | 配置路径 |
|:-------|:---------|
| `v2.0-basic-en` | `firmware/en/v2.0/dual-core/basic/config.yaml` |
| `v2.0-basic-zh` | `firmware/zh/v2.0/dual-core/basic/config.yaml` |
| `v2.0-ds18b20-en` | `firmware/en/v2.0/dual-core/ds18b20/config.yaml` |
| `v2.0-ds18b20-zh` | `firmware/zh/v2.0/dual-core/ds18b20/config.yaml` |
| `v2.0-ds18b20-radar-en` | `firmware/en/v2.0/dual-core/ds18b20-radar/config.yaml` |
| `v2.0-ds18b20-radar-zh` | `firmware/zh/v2.0/dual-core/ds18b20-radar/config.yaml` |

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

1. 确认新固件与硬件版本匹配：2026-11-12 之后的双核成品刷当前双核构建；更早的单核老设备必须刷归档单核构建；
2. 记录当前 `T-Min` / `T-Max` 等参数（`restore_value` 存在设备 NVS 中，正常 OTA 会保留，但换分区表的刷写可能清零）；
3. 避免在无人值守时远程 OTA——断电会需要现场救砖。
