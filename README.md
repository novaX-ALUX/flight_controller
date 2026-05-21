# novaX Flight Controller

[한국어](README_ko.md) | [中文](README_zh.md) | [日本語](README_ja.md)

Board definitions, build scripts, and firmware releases for novaX flight controllers.

## Supported Boards

| Board | MCU | IMU | Baro | Compass | GPS | Firmware |
|-------|-----|-----|------|---------|-----|----------|
| AF-F4 nano | STM32F405 | ICM-42688-P | SPL06 | QMC5883P (ext) | MAX-M10S | ArduPilot / Betaflight |
| AF-H7 nano | STM32H743 | Dual ICM-42688-P | DPS310 | IST8310 (int) | - | ArduPilot / Betaflight |

## Repository Structure

```
├── firmware/
│   ├── ardupilot/              # ArduPilot source (git submodule)
│   └── betaflight/             # Betaflight source (git submodule)
├── boards/
│   ├── AF-F4_nano/
│   │   ├── ardupilot/          # hwdef.dat, hwdef-bl.dat, defaults.parm
│   │   ├── betaflight/         # config.h
│   │   └── docs/               # Schematic
│   └── AF-H7_nano/
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
./scripts/build_ap.sh AF-F4_nano copter
./scripts/build_ap.sh AF-H7_nano copter
```

Bootloader is built automatically on first run if not present.

### Build Betaflight

```bash
# Install ARM toolchain (one-time, requires GCC 13.3.1)
cd firmware/betaflight && make arm_sdk_install && cd ../..

# Build
./scripts/build_bf.sh AF-F4_nano
./scripts/build_bf.sh AF-H7_nano
```

### Output

Firmware artifacts are collected in `releases/<board>/`:

```bash
ls releases/AF-F4_nano/ardupilot/
# arducopter.apj  arducopter_with_bl.hex  AF-F4_nano_bl.bin  ...

ls releases/AF-H7_nano/betaflight/
# betaflight_AF-H7_nano.hex  ...
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
