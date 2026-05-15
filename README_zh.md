# novaX 飞控

[English](README.md) | [한국어](README_ko.md) | [日本語](README_ja.md)

novaX 系列飞控的板级定义、构建脚本和固件发布产物。

## 支持的板卡

| 板卡 | MCU | IMU | 气压计 | 罗盘 | GPS | 固件 |
|------|-----|-----|--------|------|-----|------|
| novaX_F405 | STM32F405 | ICM-42688-P | SPL06 | QMC5883P (外置) | MAX-M10S | ArduPilot / Betaflight |
| novaX_H743_V1 | STM32H743 | 双 ICM-42688-P | DPS310 | IST8310 (内置) | - | ArduPilot / Betaflight |

## 目录结构

```
├── firmware/
│   ├── ardupilot/              # ArduPilot 源码 (git submodule)
│   └── betaflight/             # Betaflight 源码 (git submodule)
├── boards/
│   ├── novaX_F405/
│   │   ├── ardupilot/          # hwdef.dat, hwdef-bl.dat, defaults.parm
│   │   ├── betaflight/         # config.h
│   │   └── docs/               # 原理图
│   └── novaX_H743_V1/
│       ├── ardupilot/          # hwdef.dat, hwdef-bl.dat, defaults.parm
│       ├── betaflight/         # config.h
│       └── docs/               # 原理图
├── scripts/
│   ├── sync_ap_board.sh        # 将板级定义软链到 AP 源码树
│   ├── build_ap.sh             # 配置 + 编译 + 打包 (ArduPilot)
│   ├── build_bf.sh             # 编译 + 打包 (Betaflight)
│   └── package_fw.sh           # 收集固件产物到 releases/
├── releases/                   # 本地编译产物（已 gitignore）
│   └── <board>/
│       ├── ardupilot/          # .apj, .hex, bootloader
│       └── betaflight/         # .hex, .bin
└── GitHub Releases             # 发布的固件压缩包
```

## 快速开始

### 克隆

```bash
git clone --recurse-submodules --shallow-submodules https://github.com/novaX-ALUX/flight_controller.git
cd flight_controller
```

### 编译 ArduPilot

```bash
./scripts/build_ap.sh novaX_F405 copter
./scripts/build_ap.sh novaX_H743_V1 copter
```

首次编译时 bootloader 会自动构建。

### 编译 Betaflight

```bash
# 安装 ARM 工具链（仅需一次，要求 GCC 13.3.1）
cd firmware/betaflight && make arm_sdk_install && cd ../..

# 编译
./scripts/build_bf.sh novaX_F405
./scripts/build_bf.sh novaX_H743_V1
```

### 产物

固件产物收集在 `releases/<board>/` 下：

```bash
ls releases/novaX_F405/ardupilot/
# arducopter.apj  arducopter_with_bl.hex  novaX_F405_bl.bin  ...

ls releases/novaX_H743_V1/betaflight/
# betaflight_novaX_H743_V1.hex  ...
```

## 发布固件

```bash
# 创建 GitHub Release，自动打包所有板卡固件为 zip
./scripts/release.sh v1.0.0
```

## 烧录方式

| 方式 | 文件 | 场景 |
|------|------|------|
| STLink / DFU | `*_with_bl.hex` | 首次烧录（含 bootloader） |
| Mission Planner | `.apj` | ArduPilot OTA 更新 |
| BF Configurator | `.hex` | Betaflight 更新 |

## 工作原理

板级定义放在 `boards/` 下，与固件源码分离。`sync_ap_board.sh` 通过相对路径软链将其挂载到 ArduPilot 源码树，编译系统即可识别。

更新固件源码不影响板级配置：

```bash
cd firmware/ardupilot && git pull
```

## 许可证

硬件设计文件为 novaX-ALUX 专有。
固件定义文件遵循上游许可证（GPLv3）。
