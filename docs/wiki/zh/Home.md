# 首页 · HomeAssistant-PWM-Fan-Controlx4

**中文** · [English](Home-EN)

> 一个基于 ESPHome 的 4 路 PWM 风扇控制器：4 路独立调速、4 路转速回读、可选 DS18B20 温度闭环、可选 LD2402G 毫米波人体存在检测，同时提供 Home Assistant 集成、Web 控制面板和 HTTP REST API。

![PCB 实物](https://raw.githubusercontent.com/YUAXI/HomeAssistant-PWM-Fan-Controlx4/master/docs/images/hardware/pcb.jpg)

## 这是什么

| 项目 | 说明 |
|:-----|:-----|
| 主控 | ESP32-WROOM-32-N4（ESP-IDF 框架，Wi-Fi + BLE） |
| 风扇通道 | 4 路，独立 PWM（25 kHz）+ 独立电源开关 + 独立转速输入 |
| 调速范围 | 1%–100%（`speed_count: 100`），支持完全断电停转 |
| 供电 | DC 12V / 2A 以上（推荐）；Type-C 5V 仅用于刷写调试 |
| 控制入口 | Home Assistant（ESPHome 集成）、浏览器 Web 面板、HTTP REST API |
| 扩展能力 | DS18B20 1-Wire 温度总线（最多 4 路）、LD2402G 24GHz 雷达、BLE Proxy |
| 本地闭环 | v2.0 DS18B20 固件内置温控算法，断电断网也能独立运行 |

## Wiki 导航

| 页面 | 内容 |
|:-----|:-----|
| [快速上手](Getting-Started) | 开箱检查、供电、首次配网、刷写固件、接入 Home Assistant |
| [固件版本](Firmware) | 4 个当前双核固件（中英双版本）与归档单核构建的差异、选型决策、Release 产物、自定义编译、多设备命名 |
| [实体参考](Entities) | 全部实体清单（风扇 / 转速 / 温度 / 参数 / 诊断）与默认值、取值范围 |
| [温度控制](Temperature-Control) | DS18B20 接线、1-Wire 索引、线性调速算法、参数调优、异常行为 |
| [毫米波雷达](Radar) | LD2402G 接线与串口协议、抗干扰算法、距离门限调参、联动示例 |
| [HTTP API](HTTP-API) | REST 端点全集、中文实体名编码、curl / Python / PowerShell 示例、SSE 事件流 |
| [Home Assistant](Home-Assistant) | 集成添加、实体美化、仪表板卡片、自动化模板（温控 / 静音 / 告警） |
| [硬件资料](Hardware) | GPIO 全表、电源树、关键器件、接口丝印、结构件与装配要点 |
| [故障排查](Troubleshooting) | 按症状定位：不启动、不上线、风扇不转、转速为 0、雷达误报、OTA 失败 |
| [常见问题](FAQ) | 能带多大风扇、能不能改 24V、能不能不用 HA、商用授权等 |
| [开发指南](Development) | 仓库结构、改引脚 / 加通道、本地编译、CI 与发布流程、贡献方式 |
| [更新记录](Changelog) | 固件与硬件的版本演进、行为变更与升级注意事项 |

## 一分钟上手

```text
1. 2026-11-12 之后购买的成品都是双核 → 下载当前双核 Release 固件（-en 英文主推 / -zh 中文）；更早的单核老设备要用归档单核构建（见下方「版本速查」）
2. Type-C 连电脑，用 ESPHome Web 或 esptool 刷 .factory.bin
3. 手机连热点 ESP32-Fan-22810 → 打开 http://192.168.4.1 配网
4. 浏览器打开 http://<设备IP> 即可控制；HA 中添加 ESPHome 集成并填入 API 加密密钥
```

API 加密密钥（所有固件同一把）：

```text
LqGIGJ3qyRc+6X6hsMe5vAms+Jyh2lOMh1FQu8yyuzk=
```

## 版本速查

每个版本都有中英两套固件：英文版在 `firmware/en/`（**主要推荐**，实体名为 `Fan 1`、`Temp A`、`Uptime`…），中文版在 `firmware/zh/`（实体名为 `风扇 1`、`温度 A`、`设备运行时间`…）。两者引脚、逻辑、节点名完全一致，只有实体名不同；把下表路径中的 `zh/` 换成 `en/` 即得到英文版配置。

| 固件 | 处理器 | 温度 | 雷达 | 配置文件（中文版） | Release 产物 |
|:-----|:------:|:----:|:----:|:---------|:-------------|
| v2.0 Basic | 双核 | - | - | `firmware/zh/v2.0/dual-core/basic/config.yaml` | `v2.0-basic-en` / `v2.0-basic-zh` |
| v2.0 DS18B20 | 双核 | ✅ | - | `firmware/zh/v2.0/dual-core/ds18b20/config.yaml` | `v2.0-ds18b20-en` / `v2.0-ds18b20-zh` |
| v2.0 DS18B20+雷达 | 双核 | ✅ | ✅ | `firmware/zh/v2.0/dual-core/ds18b20-radar/config.yaml` | `v2.0-ds18b20-radar-en` / `v2.0-ds18b20-radar-zh` |

> ⚠️ **2026-11-12 之后售卖的成品全部是双核，当前固件为双核 v2.0。** 直接刷上表任一版本即可。
>
> **整个 v1.0 系列**与早于该日期出货的**单核板**都使用 `firmware/zh/archive/` 下的归档构建自行编译（`archive/v1.0/{dual-core,single-core}/`、`archive/v2.0/single-core/{basic,ds18b20,ds18b20-radar}/`）；这些归档构建**不再进入 CI 与 Release**。单核板无法启动双核固件；双核板也可以运行归档单核固件，只是闲置一个核心。详见 [固件版本](Firmware#归档的构建)。

## 关键参数

| 参数 | 值 |
|:-----|:---|
| 设备节点名 | `esp32pwm22810-<MAC 后 3 字节>`（如 `esp32pwm22810-a1b2c3`） |
| HA 设备名 | `ESP32 PWM 22810 <MAC 后 3 字节>` |
| 热点 SSID | `ESP32-Fan-22810`（无密码，`192.168.4.1`） |
| Web 面板 | `http://<设备IP>/`（80 端口，无需登录） |
| mDNS | `http://esp32pwm22810-xxxxxx.local/` |
| OTA 密码 | `4283bb50a8cd66774ce91d2c9d412cf2` |
| PWM 载波 | 25 kHz |

## 相关链接

- [GitHub Releases（预编译固件）](https://github.com/YUAXI/HomeAssistant-PWM-Fan-Controlx4/releases)
- [English README（仓库主文档）](https://github.com/YUAXI/HomeAssistant-PWM-Fan-Controlx4/blob/master/readme.md) · [中文 README](https://github.com/YUAXI/HomeAssistant-PWM-Fan-Controlx4/blob/master/README_ZH.md)
- [ESPHome 官方文档](https://esphome.io/)
- [Home Assistant ESPHome 集成](https://www.home-assistant.io/integrations/esphome/)

![Home Assistant 控制界面](https://raw.githubusercontent.com/YUAXI/HomeAssistant-PWM-Fan-Controlx4/master/docs/images/screenshots/ha01.png)
