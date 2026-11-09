# 快速上手

[← 首页](Home) · **中文** · [English](Getting-Started-EN)

本文覆盖从拆箱到在 Home Assistant 里看到 4 个风扇的完整流程。已经刷好固件的成品设备可以直接跳到 [2.2 首次配网](#22-首次配网)。

## 2.1 开箱与供电

### 包装内容（成品）

| 部件 | 说明 |
|:-----|:-----|
| 控制器主板 | v1.0 或 v2.0，已预装 ESP32 模组 |
| 风扇接口 | 4 个标准 4PIN 风扇座（12V / GND / 转速 / PWM） |
| DC 电源座 | 5.5×2.1mm，12V 输入 |
| Type-C 接口 | 5V，仅刷写调试，**不能驱动风扇** |

### 供电要求

| 供电方式 | 接口 | 电压 | 说明 |
|:---------|:-----|:-----|:-----|
| **DC 接口（推荐）** | DC 座 | 12V / 2A 以上 | 正常运行，同时为风扇和 ESP32 供电 |
| Type-C 接口 | USB-C | 5V | 仅用于刷写和调试；5V 下风扇基本不转 |

> 4 路风扇同时满载时，请按风扇铭牌电流之和预留余量：4 × 0.3A ≈ 1.2A，建议 12V / 3A 电源更稳。板载 DC-DC（TPS5430）为 5V 轨供电，3.3V 由 AMS1117 提供。

### 首次上电自检

- 上电后风扇**默认不转**：4 路电源开关的 `restore_mode` 为 `ALWAYS_OFF`，风扇实体的 `restore_mode` 为 `RESTORE_DEFAULT_OFF`。
- 未配网时设备建立热点 `ESP32-Fan-22810`（无密码）。
- 主板丝印/模组旁可看到 ESP32 模组，Type-C 旁为 CH340C 串口芯片。

## 2.2 首次配网

1. 手机或电脑连接无密码热点 **`ESP32-Fan-22810`**。
2. 浏览器访问 **`http://192.168.4.1`**（推荐；会自动弹出 captive portal 配网页）。
3. 选择目标 Wi-Fi、输入密码并提交。
4. 设备保存凭据后自动重启并连接。

补充说明：

| 场景 | 做法 |
|:-----|:-----|
| 忘记设备 IP | 看路由器 DHCP 列表，或访问 `http://esp32pwm22810-xxxxxx.local/`（`xxxxxx` 为 MAC 后 3 字节，全小写） |
| 想跳过配网 | 刷写前在配置里预置 `wifi.ssid` / `wifi.password`（见 [固件版本](Firmware#自定义编译)） |
| 换 Wi-Fi | 重新上电后若连不上原网络，会自动回落到热点模式；也可通过 HA 的 ESPHome「配置」→ 重新配网 |

## 2.3 刷写固件

### 先选固件

| 你的硬件 | 建议固件 |
|:---------|:---------|
| 不确定单核/双核 | **任意 v2.0 固件**或 **v1.0 单核**（单核固件在双核芯片上同样能运行） |
| 确认是双核 | v1.0 双核，或 v2.0 |
| 需要本地温控 | v2.0 DS18B20 |
| 需要人体存在检测 | v2.0 DS18B20 + 雷达 |

详细对比见 [固件版本](Firmware)。

### 方式 A：ESPHome Web（最简单，无需装工具链）

1. Type-C 连接电脑，打开 <https://web.esphome.io>（Chrome / Edge）。
2. 点击 **Connect**，选择出现的串口（Windows 下形如 `COM5`，芯片为 `CH340`）。
3. 选择 **Install** → 上传本地下好的 **`.firmware.factory.bin`**（含引导程序，必须用 factory 版本）。
4. 等待写入完成，设备自动重启。

### 方式 B：esptool 命令行（可选，便于批量/排错）

```bash
# 安装
pip install esptool

# 首次刷写：factory 固件写到 0x0
esptool.py --chip esp32 --port COM5 --baud 460800 \
  write_flash 0x0 v2.0-basic.firmware.factory.bin

# 若只拿到普通 app 固件（.firmware.bin），偏移为 0x10000
esptool.py --chip esp32 --port COM5 --baud 460800 \
  write_flash 0x10000 v2.0-basic.firmware.bin

# 进不了下载模式时：按住 BOOT（IO0）再按一下 RST，然后松开 BOOT
```

Linux / macOS 把 `COM5` 换成 `/dev/ttyUSB0`、`/dev/cu.usbserial-*`；下载失败时把波特率降到 `115200`。

### 方式 C：ESPHome 编译并刷写（自定义配置时使用）

```bash
pip install esphome
esphome compile firmware/v2.0/single-core/ds18b20/config.yaml
esphome upload  firmware/v2.0/single-core/ds18b20/config.yaml   # 按提示选串口
```

### 方式 D：OTA 升级已联网设备

```bash
# 方式 1：用 ESPHome CLI 指定设备地址
esphome upload firmware/v2.0/single-core/ds18b20/config.yaml --device 192.168.1.50

# 方式 2：在 ESPHome Dashboard 里点 INSTALL → Wirelessly
# 方式 3：HA 中 ESPHome 集成设备页 → 三个点 → 更新（有可用更新时）
```

OTA 目标填该设备自己的 IP 或 `<节点名>.local`；OTA 密码为 `4283bb50a8cd66774ce91d2c9d412cf2`。

> ⚠️ OTA 过程中断电会损坏应用分区，需回到 USB 刷写。升级前请确认固件与硬件版本一致。

## 2.4 接入 Home Assistant

1. **设置 → 设备与服务 → 添加集成**，搜索 **ESPHome**。
2. 选择自动发现的 `ESP32 PWM 22810 xxxxxx`，或手动输入设备 IP。
3. 输入 API 加密密钥并提交：

   ```text
   LqGIGJ3qyRc+6X6hsMe5vAms+Jyh2lOMh1FQu8yyuzk=
   ```

4. 成品通常得到下表实体（完整清单见 [实体参考](Entities)）。

| 实体类型 | 数量 | 说明 |
|:---------|:----:|:-----|
| 风扇 | 4 | 独立开关 + 1–100% 调速 |
| 转速传感器 | 4 | 单位 RPM，4 秒刷新 |
| 温度传感器 | 4 | 仅 DS18B20 / 雷达固件，名称 温度 A–D |
| 雷达实体 | 2 | 仅雷达固件：存在状态 + 目标距离 |
| 蓝牙代理 | 1 | 扩展 HA 蓝牙覆盖 |
| 诊断实体 | 5 | 运行时间、Wi-Fi 信号、IP、SSID、ESPHome 版本 |

如果一直显示「已发现」但添加失败，通常是 IP 填错或被防火墙拦截：先在浏览器打开 `http://<设备IP>/` 确认能访问。

## 2.5 Web 控制面板

浏览器访问 `http://<设备IP>/` 即可，不依赖 Home Assistant：

- 查看 4 路风扇状态和转速；
- 拖动滑块独立调节风速；
- 查看温控参数（`T-Min` / `T-Max` / `F-Min` / `F-Max`）与雷达门限；
- 底部可展开实时日志，便于排查。

面板外观由 ESPHome `web_server` 提供，未设置 `version` 时使用默认版本（新版 ESPHome 默认 v2）。需要 HA 风格界面可在配置中加 `version: 3`。

## 2.6 多台设备同时接入

同一份固件可以刷到任意多台设备：固件启用了 `name_add_mac_suffix: true`，每台设备启动时把自身 MAC 后 3 字节追加进名字。

| 项目 | 形态 |
|:-----|:-----|
| 节点名 | `esp32pwm22810-a1b2c3` |
| HA 设备名 | `ESP32 PWM 22810 a1b2c3` |
| mDNS | `esp32pwm22810-a1b2c3.local` |
| 实体 ID | `<域名>.esp32_pwm_22810_a1b2c3_<实体名>` |

添加步骤与单台相同，重复执行即可，多台设备会作为独立条目并存。

> **为什么要加后缀**：HA 以固件里的 `name` 作为 ESPHome 设备唯一标识。多台设备同名时，HA 会触发[名称冲突处理](https://www.home-assistant.io/integrations/esphome/#reconfiguration-and-device-replacement)，只给「迁移」或「覆盖」两个选项，后添加的设备会直接覆盖已有设备。

如果之前用旧的重名固件接入过设备，请先删除旧条目再重新添加。核对设备身份的办法：

1. HA 设备页的 MAC 地址最后 3 字节；
2. 路由器 DHCP 客户端列表里的主机名；
3. 串口日志开头打印的 MAC；
4. 浏览器打开 `http://<设备IP>/`，日志区会显示节点名。

## 下一步

- 想让温度自动控速 → [温度控制](Temperature-Control)
- 想按人体存在联动 → [毫米波雷达](Radar)
- 想用脚本调用 → [HTTP API](HTTP-API)
- 设备不听话 → [故障排查](Troubleshooting)
