# novaX Flight Controller

[한국어](README_ko.md) | [中文](README_zh.md) | [日本語](README_ja.md)

Board definitions, build scripts, and firmware releases for novaX flight controllers.

## Supported Boards

| Board | MCU | IMU | Baro | Compass | GPS | Firmware |
|-------|-----|-----|------|---------|-----|----------|
| novaX_F405 | STM32F405 | ICM-42688-P | SPL06 | QMC5883P (ext) | MAX-M10S | ArduPilot / Betaflight |
| novaX_H743_V1 | STM32H743 | Dual ICM-42688-P | DPS310 | IST8310 (int) | - | ArduPilot / Betaflight |

## Repository Structure

```
├── firmware/
│   ├── ardupilot/              # ArduPilot source (git submodule)
│   └── betaflight/             # Betaflight source (git submodule)
├── boards/
│   ├── novaX_F405/
│   │   ├── ardupilot/          # hwdef.dat, hwdef-bl.dat, defaults.parm
│   │   ├── betaflight/         # config.h
│   │   └── docs/               # Schematic
│   └── novaX_H743_V1/
│       ├── ardupilot/          # hwdef.dat, hwdef-bl.dat, defaults.parm
│       ├── betaflight/         # config.h
│       └── docs/               # Schematic
├── scripts/
│   ├── sync_ap_board.sh        # Symlink board config into AP source tree
│   ├── build_ap.sh             # Configure + build + package (ArduPilot)
│   ├── build_bf.sh             # Build + package (Betaflight)
│   └── package_fw.sh           # Collect firmware artifacts into releases/
├── releases/                   # Local build output (gitignored)
│   └── <board>/
│       ├── ardupilot/          # .apj, .hex, bootloader
│       └── betaflight/         # .hex, .bin
└── GitHub Releases             # Published firmware zips
```

## Getting Started

### Clone

```bash
git clone --recurse-submodules --shallow-submodules https://github.com/novaX-ALUX/flight_controller.git
cd flight_controller
```

### Build ArduPilot

```bash
./scripts/build_ap.sh novaX_F405 copter
./scripts/build_ap.sh novaX_H743_V1 copter
```

Bootloader is built automatically on first run if not present.

### Build Betaflight

```bash
# Install ARM toolchain (one-time, requires GCC 13.3.1)
cd firmware/betaflight && make arm_sdk_install && cd ../..

# Build
./scripts/build_bf.sh novaX_F405
./scripts/build_bf.sh novaX_H743_V1
```

### Output

Firmware artifacts are collected in `releases/<board>/`:

```bash
ls releases/novaX_F405/ardupilot/
# arducopter.apj  arducopter_with_bl.hex  novaX_F405_bl.bin  ...

ls releases/novaX_H743_V1/betaflight/
# betaflight_novaX_H743_V1.hex  ...
```

## Publishing a Release

```bash
# Create a GitHub Release with firmware zips for all boards
./scripts/release.sh v1.0.0
```

## Flashing

| Method | File | When |
|--------|------|------|
| STLink / DFU | `*_with_bl.hex` | First flash (includes bootloader) |
| Mission Planner | `.apj` | ArduPilot OTA update |
| BF Configurator | `.hex` | Betaflight update |

## How It Works

Board definitions live in `boards/`, separate from firmware source. The `sync_ap_board.sh` script creates relative symlinks into the ArduPilot source tree so the build system can find them.

Updating firmware source is independent of board configs:

```bash
cd firmware/ardupilot && git pull
```

## License

Hardware design files are proprietary to novaX-ALUX.
Firmware definitions follow their respective upstream licenses (GPLv3).
