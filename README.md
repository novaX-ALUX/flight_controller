# novaX Flight Controller

novaX 系列飞控的板级定义、固件构建脚本和发布产物。

## 支持的板卡

| 板卡 | MCU | IMU | 气压计 | 罗盘 | GPS | 固件 |
|------|-----|-----|--------|------|-----|------|
| novaX_F405 | STM32F405 | ICM-42688-P | SPL06 | QMC5883P (外置) | MAX-M10S | ArduPilot |
| novaX_H743_V1 | STM32H743 | Dual ICM-42688-P | DPS310 | IST8310 (内置) | - | ArduPilot / Betaflight |

## 目录结构

```
├── firmware/
│   ├── ardupilot/              # ArduPilot 源码 (git submodule)
│   └── betaflight/             # Betaflight 源码 (git submodule)
├── boards/
│   ├── novaX_F405/
│   │   ├── ardupilot/          # hwdef.dat, hwdef-bl.dat, defaults.parm
│   │   └── docs/               # 原理图
│   └── novaX_H743_V1/
│       ├── ardupilot/          # hwdef.dat, hwdef-bl.dat, defaults.parm
│       ├── betaflight/         # config.h
│       └── docs/               # 原理图
├── scripts/
│   ├── sync_ap_board.sh        # 将板级定义软链到 AP 源码树
│   ├── build_ap.sh             # 配置 + 编译 + 打包
│   └── package_fw.sh           # 收集固件产物到 releases/
└── releases/
    └── <board>/ardupilot/      # 编译产物 (.apj, .hex, bootloader)
```

## 快速开始

```bash
# 克隆（含固件源码）
git clone --recurse-submodules --shallow-submodules https://github.com/novaX-ALUX/flight_controller.git

# 编译 ArduPilot
./scripts/build_ap.sh novaX_F405 copter
./scripts/build_ap.sh novaX_H743_V1 copter

# 产物
ls releases/<board>/ardupilot/
```

## 工作流

- 板级定义在 `boards/` 下维护，不直接修改固件源码
- `sync_ap_board.sh` 通过相对路径软链将板级定义挂载到 AP 源码树
- 更新固件源码：`cd firmware/ardupilot && git pull`，板级配置不受影响
