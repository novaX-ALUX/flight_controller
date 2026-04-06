# novaX Flight Controller

novaX F405-8S 飞控固件构建工程。

## 目录结构

```
flight_controller/
├── firmware/
│   └── ardupilot/                  # ArduPilot 源码 (shallow clone, 不要直接改)
├── boards/
│   └── novaX_F405/
│       ├── ardupilot/              # 板级定义 (hwdef.dat, hwdef-bl.dat, defaults.parm)
│       ├── docs/                   # 原理图等硬件文档
│       └── metadata.yaml           # 板卡元信息
├── scripts/
│   ├── sync_ap_board.sh            # 将板级定义软链到 AP 源码树
│   ├── build_ap.sh                 # 配置 + 编译 + 打包 (一条龙)
│   └── package_fw.sh               # 收集固件产物到 releases/
├── build/
│   └── ardupilot -> ...            # 指向 AP 编译中间目录的软链
└── releases/
    └── novaX_F405/ardupilot/       # 最终固件产物 (.apj, .hex, bootloader)
```

## 快速开始

```bash
# 编译 Copter 固件 (自动 sync + configure + build + package)
./scripts/build_ap.sh novaX_F405 copter

# 产物在
ls releases/novaX_F405/ardupilot/
```

## 工作流说明

板级定义文件放在 `boards/` 目录下，不在 AP 源码树内。`sync_ap_board.sh` 通过相对路径软链将其挂载到 AP 的 `libraries/AP_HAL_ChibiOS/hwdef/novaX_F405`，编译系统就能识别到这个板卡。

更新 AP 源码时直接在 `firmware/ardupilot/` 里 `git pull`，板级配置不受影响。
