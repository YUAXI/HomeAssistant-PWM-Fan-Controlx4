# 毫米波雷达（LD2402G）

[← 首页](Home) · **中文** · [English](Radar-EN)

仅 `v2.0-ds18b20-radar` 固件启用。雷达用于**人体存在检测**，并把「有人 / 距离」两个实体交给 Home Assistant，由你做联动。

## 接线

| 雷达接口 | 控制器接口 | 说明 |
|:---------|:-----------|:-----|
| TX | GPIO4（UART RX） | 雷达 → 控制器 |
| RX | GPIO5（UART TX） | 控制器 → 雷达 |
| VCC | 5V（v2.0 4PIN 开发者排针） | 注意电流余量 |
| GND | GND | 共地 |

串口参数：**115200 8N1**。TX/RX 是交叉的——如果接反，日志里会完全看不到数据。

## 串口行为

### 上电初始化

开机时（`on_boot`, `priority: -100`）固件先发两帧，间隔 200ms：

```text
55 5A 02 01 AA    # 开启上报 / 配置帧
55 01 01 00 AA    # 上报使能
```

若雷达无输出，先确认这两帧是否发出（串口日志会打印「正在发送激活指令给 LD2402G...」）。

### 上报格式

雷达以 ASCII 行输出距离，固件按行解析：

```text
distance:35\r\n     → 0.35 m
distance:180\r\n    → 1.80 m
```

解析规则：以 `0x0A`（`\n`）分行，忽略 `0x0D`（`\r`），用 `sscanf("distance:%d")` 取厘米值再除以 100 转成米。

### 为什么用 `uart.debug` 而不是标准 UART 组件

雷达只需要**收**（控制器基本不解析二进制协议），所以固件用：

```yaml
uart:
  - id: radar_uart
    tx_pin: GPIO5
    rx_pin: GPIO4
    baud_rate: 115200
    debug:
      direction: RX
      dummy_receiver: true     # 数据只进 lambda，不交给真实 UART 设备
      sequence:
        - lambda: |-
            ...自定义解析...
```

`dummy_receiver: true` 表示字节流直接进入 `lambda` 的 `bytes`，不创建 UART 设备对象。**因此这条串口不能同时挂别的 UART 组件**（想加 RS485 请另开一条 UART，用别的引脚）。

## 抗干扰算法

雷达的原始距离会抖动、会有固定反射（金属柜、机箱），固件做了三层过滤：

| 规则 | 条件 | 结果 |
|:-----|:-----|:-----|
| ① 区间过滤 | 距离 < `Min` 或 > `Max` | 目标 = 无人，距离 = `NaN` |
| ② 变化检测 | 与上次距离差 **> 0.01 m** | 刷新「最后变化时间」并记录新距离 |
| ③ 静止超时 | 在区间内但 **5 秒**没有变化 | 判定为固定伪目标 → 无人，距离 = `NaN` |

三者都通过时：目标 = 有人，距离 = 当前读数。

```text
读数 → 超出 [Min, Max]？ ──是──→ 无人 / 距离 NaN
              │否
              ↓
     距离变化 > 1cm？ ──是──→ 更新时间戳
              ↓
     距上次变化 > 5s？ ──是──→ 无人 / 距离 NaN（判定为固定反射）
              │否
              ↓
           有人 / 距离 = 读数
```

**设计取舍**：坐着不动的人（变化 < 1cm、持续 5 秒）会被判为「无人」。这是为了压掉固定反射的噪声，代价是不支持「静止存在检测」。如果需要更长的静止容忍时间，改固件里的 `5000` 毫秒常量即可：

```cpp
if (millis() - last_change_time > 5000) {   // 调大，例如 30000
```

> 当前固件只使用雷达的 ASCII 距离上报，不使用其二进制/存在检测协议；「有人」判定完全由上表逻辑决定。

## 参数

| 参数 | 范围 | 步长 | 默认 | 作用 |
|:-----|:-----|:-----|:----:|:-----|
| 雷达 最近过滤门限 Min | 0.0–2.0 m | 0.05 | 0.10 m | 小于该距离的反射忽略（贴脸误触、机箱内反射） |
| 雷达 最远过滤门限 Max | 0.5–8.0 m | 0.1 | 1.50 m | 大于该距离忽略（隔壁房间、走廊尽头） |

两个参数都掉电保持，可以在 HA 里随时拖滑块调整，立即生效（下一个上报周期）。

调参方法：

1. 先看「雷达目标距离 Dist」的实时数值（站在目标位置走动，观察读数）；
2. 把 `Min` 设到目标区域近端（比如座椅前 0.3 m）；
3. 把 `Max` 设到房间远端（比如 2.5 m），把走廊和邻居挡掉；
4. 验证「静坐 10 秒」→ 期望变「无人」；「挥手」→ 立即变「有人」。

## 实体

| 实体 | 类型 | 说明 |
|:-----|:-----|:-----|
| 雷达检测到目标 Target | binary_sensor | 有人 = `on`；被过滤时 = `off` |
| 雷达目标距离 Dist | sensor | 单位 m；被过滤时发布 `NaN`（HA 显示 unknown） |

## 联动示例

### 有人加速、无人降速

```yaml
alias: "机柜风扇：有人全速，无人降速"
mode: restart
trigger:
  - platform: state
    entity_id: binary_sensor.esp32_pwm_22810_a1b2c3_lei_da_jian_ce_dao_mu_biao_target
action:
  - choose:
      - conditions:
          - condition: state
            entity_id: binary_sensor.esp32_pwm_22810_a1b2c3_lei_da_jian_ce_dao_mu_biao_target
            state: "on"
        sequence:
          - service: fan.set_percentage
            target: { entity_id: fan.esp32_pwm_22810_a1b2c3_feng_shan_1 }
            data: { percentage: 100 }
      - conditions:
          - condition: state
            entity_id: binary_sensor.esp32_pwm_22810_a1b2c3_lei_da_jian_ce_dao_mu_biao_target
            state: "off"
            for: "00:02:00"          # 无人持续 2 分钟再降速，避免误判
        sequence:
          - service: fan.set_percentage
            target: { entity_id: fan.esp32_pwm_22810_a1b2c3_feng_shan_1 }
            data: { percentage: 30 }
```

> 上面的 `entity_id` 只是示意，请到自己的 HA 实体页复制真实 ID（中文名会保留在 ID 里）。

### 与本地温控叠加的正确姿势

不要直接用 HA 去写风扇速度——若该路风扇绑定了温度源，5 秒后会被本地闭环覆盖。推荐：

| 需求 | 做法 |
|:-----|:-----|
| 有人时更激进散热 | 用 `number.set_value` 调 `F-Max`（如 100），无人时调到 60 |
| 有人时降低噪音 | 调 `F-Min` 到 25，保证一起转就是低噪 |
| 完全接管某一路 | 把该路 `FN-Src` 设为「未绑定」，再让 HA 自动化控制风扇 |

```yaml
action:
  - service: number.set_value
    target: { entity_id: number.esp32_pwm_22810_a1b2c3_feng_shan_1_zui_gao_feng_su_f_max }
    data: { value: 100 }
```

## 排错

| 现象 | 排查 |
|:-----|:-----|
| Dist 一直是 unknown | TX/RX 是否接反；雷达是否 5V 供电；串口日志有没有 `distance:` 行 |
| 一直显示有人 | `Min` 太小（机箱内反射）；`Max` 太大（隔壁走廊）；先看 Dist 实际数值 |
| 一直显示无人 | 人站的位置超出 `[Min, Max]`；或距离变化 < 1cm 被静止判定吃掉 |
| 数值来回跳 | 正常现象，雷达分辨率约 1cm；联动时加 `for:` 延时去抖 |
| 日志被雷达数据刷屏 | 正常（`uart.debug` 会打印收发字节）；把 `logger.level` 保持 `INFO` 即可 |
| 重启后雷达无数据 | 检查 `on_boot` 两帧是否发出（日志有「正在发送激活指令…」） |

## 供电注意

雷达 + 4 路风扇 + 4 个温度探头都从板卡的 5V/3.3V 轨取电：

- 雷达模块峰值电流按 100mA 以上预算；
- 4 路风扇满载电流走 12V 轨，与雷达无关；
- 若雷达频繁重启或数据中断，先量 5V 轨电压（TPS5430 输出），并检查 4PIN 排针接触。
