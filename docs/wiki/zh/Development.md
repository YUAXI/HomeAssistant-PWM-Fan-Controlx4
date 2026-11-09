# 开发指南

[← 首页](Home) · **中文** · [English](Development-EN)

## 仓库结构

```text
HomeAssistant-PWM-Fan-Controlx4/
├── readme.md                       # 中文总览（面向用户）
├── README_EN.md                    # English overview
├── LICENSE                         # MIT
├── .github/workflows/build.yml     # 5 个固件矩阵编译 + 自动 Release
├── docs/
│   ├── images/                     # 图片资源（硬件照、截图、图表、捐赠码）
│   └── wiki/                       # 本 Wiki 源文件（zh/ en/ + 同步脚本）
├── firmware/
│   ├── v1.0/
│   │   ├── dual-core/config.yaml           # CONFIG_FREERTOS_UNICORE 注释掉
│   │   └── single-core/config.yaml         # 单核
│   └── v2.0/single-core/
│       ├── basic/config.yaml               # 与 v1.0 单核内容相同
│       ├── ds18b20/config.yaml             # + 1-Wire + 温控实体与算法
│       └── ds18b20-radar/config.yaml       # + UART 雷达解析 + 雷达调参
└── hardware/
    ├── v1.0/{pcb,3d-models}/
    └── v2.0/{pcb,3d-models}/
```

## 配置文件解剖

所有固件变体的骨架一致，顺序如下（修改时建议保持这个顺序，方便 diff）：

| 段 | 作用 |
|:---|:-----|
| `esphome` | 节点名、`name_add_mac_suffix`、`friendly_name`、（雷达版）`on_boot` 初始化 |
| `esp32` | 板型、ESP-IDF 框架、`CONFIG_FREERTOS_UNICORE`、panic 重启 |
| `logger` | 日志级别 `INFO` |
| `api` | 原生 API + 加密密钥 |
| `ota` | ESPHome OTA + 密码 |
| `wifi` / `captive_portal` | 热点兜底 + 配网页面 |
| `esp32_ble_tracker` / `bluetooth_proxy` | BLE 代理 |
| `web_server` | 80 端口 Web 面板与 REST API |
| `one_wire` | DS18B20 总线（GPIO14，仅温度版） |
| `uart` | 雷达串口 + `debug.sequence` 解析（仅雷达版） |
| `output` | 4 × LEDC 25 kHz PWM |
| `switch` | 4 × 风扇电源开关（`internal: true`，`ALWAYS_OFF`） |
| `select` | 4 × 温度源绑定（仅温度版） |
| `number` | 温控参数 16 个（+ 雷达门限 2 个） |
| `interval` | 5 秒温控主循环 |
| `binary_sensor` / `sensor` / `text_sensor` | 雷达状态、转速、温度、诊断 |
| `fan` | 4 × speed fan，`on_turn_on/off` 联动电源开关 |

## 加第 5 路风扇

假设新通道用 GPIO15（PWM）、GPIO34（转速，仅输入）、GPIO27（电源开关）：

```yaml
output:
  - platform: ledc
    pin: GPIO15
    id: fan5_pwm
    frequency: 25000Hz

switch:
  - platform: gpio
    pin: GPIO27
    id: fan5_pwr
    internal: true
    restore_mode: ALWAYS_OFF

sensor:
  - platform: pulse_counter
    pin:
      number: GPIO34
      mode: INPUT
    name: "风扇 5 转速"
    id: fan5_rpm
    unit_of_measurement: "RPM"
    update_interval: 4s
    count_mode: {rising_edge: DISABLE, falling_edge: INCREMENT}
    internal_filter: 13us
    filters:
      - multiply: 0.5

fan:
  - platform: speed
    output: fan5_pwm
    name: "风扇 5"
    id: my_fan5
    speed_count: 100
    restore_mode: RESTORE_DEFAULT_OFF
    on_turn_on:
      - switch.turn_on: fan5_pwr
    on_turn_off:
      - switch.turn_off: fan5_pwr
```

要接入温控，还需要对应的 `select`（`f5_source`）、4 个 `number`（`f5_t_min` 等），并在 `interval` 的 lambda 里复制一段 `s5` 分支（把 `my_fan1` 换成 `my_fan5`，变量换名）。

> ESP32 剩余可用引脚有限（详见 [硬件资料](Hardware#gpio-分配)）。做到 8 路建议加 IO 扩展芯片，而不是硬挤 GPIO。

## 本地编译

```bash
# 方式 1：本地 Python（推荐，与 CI 一致）
python -m venv .venv && . .venv/bin/activate      # Windows: .venv\Scripts\activate
pip install esphome
esphome config  firmware/v2.0/single-core/basic/config.yaml   # 语法/引脚校验
esphome compile firmware/v2.0/single-core/basic/config.yaml
esphome upload  firmware/v2.0/single-core/basic/config.yaml

# 方式 2：Docker（不想污染环境）
docker run --rm -v "$PWD":/config -w /config \
  ghcr.io/esphome/esphome compile firmware/v2.0/single-core/basic/config.yaml
```

编译产物位置：`firmware/<版本>/<变体>/.esphome/build/<节点名>/.pioenvs/<节点名>/firmware.bin`（该目录已被 `.gitignore` 忽略）。

`esphome config` 是最省时间的检查——能在烧录前抓出 90% 的 YAML / 引脚 / 组件参数错误。

## 调试技巧

| 需求 | 方法 |
|:-----|:-----|
| 看启动与运行日志 | `esphome logs <config>`，或 Web 面板底部日志区 |
| 看 1-Wire 地址 | `logger.level: DEBUG`，启动日志会列出器件地址 |
| 看雷达原始字节 | 雷达版 `uart.debug` 已开启，日志会打印收发数据 |
| 临时提高日志级别 | `logger.level: DEBUG`（注意刷屏会拖慢设备） |
| 验证引脚 | `esphome config` 会报引脚冲突 |
| 单步排查温控 | 把 `interval: 5s` 临时改成 `1s`，观察响应（记得改回） |

## CI 与发布

| 项 | 值 |
|:---|:---|
| Workflow | `.github/workflows/build.yml` |
| 触发 | push 到 `master`、`workflow_dispatch` |
| 矩阵 | `v1.0-dual-core`、`v1.0-single-core`、`v2.0-basic`、`v2.0-ds18b20`、`v2.0-ds18b20-radar` |
| 失败策略 | `fail-fast: false`，单个变体失败不影响其他 |
| 缓存 | `~/.esphome`，key 为 `firmware/**/config.yaml` 的哈希 |
| 产物 | 每个变体的 `firmware*.bin`，重命名为 `<变体>.<原文件名>` |
| 发布 | 合并全部 artifact，创建以日期（`%Y.%-m.%-d`）为 tag 的 Release |

**新增一个固件变体**需要同步改 4 处，漏掉任何一处都会让文档与 CI 不一致：

1. 新建目录并写 `config.yaml`（复制最接近的变体再改）；
2. `.github/workflows/build.yml` 的 `matrix.include` 加一行 `name` + `path`；
3. `readme.md` / `README_EN.md` 的固件表、Release 对照表；
4. 本 Wiki 的 [首页](Home)、[固件版本](Firmware)、[实体参考](Entities) 里的表格。

## 提交与分支

| 类型 | 前缀 | 示例 |
|:-----|:-----|:-----|
| 新功能 | `feat:` | `feat: 增加雷达静止目标过滤` |
| 修复 | `fix:` | `fix: 修复 turn_off 编译错误` |
| 文档 | `docs:` | `docs: 补充 OTA 说明` |
| CI | `ci:` | `ci: 修复固件收集路径` |
| 杂项 | `chore:` | `chore: 移除预编译固件` |

- 主分支为 `master`，直接向 `master` 提交或开 PR 均可；
- 改动固件配置后请本地 `esphome config` + `esphome compile` 通过再提交；
- 涉及行为的改动（例如停转阈值、参数默认值）请同时更新 `readme.md` 的更新记录表与本 Wiki 的 [更新记录](Changelog)。

## 文档（Wiki）维护

本 Wiki 的源文件放在 `docs/wiki/`：

```text
docs/wiki/
├── README.md          # 如何发布 / 同步到 GitHub Wiki
├── zh/                # 中文页面（Home.md、Firmware.md …）
└── en/                # 英文页面（Home-EN.md、Firmware-EN.md …）
```

约定：

- 每个页面中英各一份，文件名规则 `<Page>.md` / `<Page>-EN.md`；
- 页面内图片统一使用 `raw.githubusercontent.com` 绝对地址（GitHub Wiki 不解析仓库相对路径）；
- 新增页面时同步更新 `zh/_Sidebar.md`、`en/_Sidebar.md` 与 `Home` 的导航表；
- 发布流程见 `docs/wiki/README.md`（GitHub Wiki 需先在网页端创建首页，之后可用脚本推送）。
