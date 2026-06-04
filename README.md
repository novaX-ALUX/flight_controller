# novaX Flight Controller

[한국어](README_ko.md) | [中文](README_zh.md) | [日本語](README_ja.md)

Board definitions, build scripts, and firmware releases for novaX flight controllers and DroneCAN peripherals.

## Supported Boards

| Board | MCU | IMU | Baro | Compass | GPS | Firmware |
|-------|-----|-----|------|---------|-----|----------|
| AF-F4 nano | STM32F405 | ICM-42688-P | SPL06 | QMC5883P (ext) | MAX-M10S | ArduPilot / Betaflight |
| AF-H7 nano | STM32H743 | Dual ICM-42688-P | DPS310 | IST8310 (int) | - | ArduPilot / Betaflight |
| AF-F7 mini&nbsp;‡ | STM32F765 | ICM-20689 + ICM-20602 + BMI055 | MS5611 | IST8310 (int) | - | ArduPilot |
| AF-H7E&nbsp;‡ | STM32H753 | ICM-42688-P + BMI088 + ICM-20649 | 2× ICP-20100 | RM3100 | - | ArduPilot |
| AP-RTK dual&nbsp;† | STM32F412 | - | - | RM3100 | Dual-antenna RTK (moving baseline) | ArduPilot AP_Periph |

† **DroneCAN peripheral** (GPS + compass node), not a flight controller. Based on the CUAV C-RTK2-HP; board ID `1085` (kept same as CUAV so it can be updated over DroneCAN).

‡ **Autopilot-class** boards with redundant IMUs. AF-F7 mini drives its PWM outputs directly (no IO co-processor); AF-H7E is a modular design with an STM32F103 IO co-processor and Ethernet. Board IDs `6201` / `6202` (novaX-ALUX reserved range `6200`–`6209`).

## Repository Structure

```
├── firmware/
│   ├── ardupilot/              # ArduPilot source (git submodule)
│   └── betaflight/             # Betaflight source (git submodule)
├── boards/
│   ├── AF-F4_nano/             # Flight controller
│   │   ├── ardupilot/          # hwdef.dat, hwdef-bl.dat, defaults.parm
│   │   ├── betaflight/         # config.h
│   │   └── docs/               # Schematic
│   ├── AF-H7_nano/             # Flight controller
│   │   ├── ardupilot/          # hwdef.dat, hwdef-bl.dat, defaults.parm
│   │   ├── betaflight/         # config.h
│   │   └── docs/               # Schematic
│   ├── AF-F7_mini/             # Flight controller (no IOMCU)
│   │   ├── ardupilot/          # hwdef.dat, hwdef-bl.dat, defaults.parm
│   │   └── docs/               # Schematic + netlist
│   ├── AF-H7E/                 # Flight controller (modular, Ethernet)
│   │   ├── ardupilot/          # hwdef.dat, hwdef-bl.dat, defaults.parm
│   │   └── docs/               # Schematics + netlists
│   └── AP-RTK_dual/            # DroneCAN AP_Periph peripheral (GPS + compass)
│       ├── ardupilot/          # hwdef.dat, hwdef-bl.dat
│       └── metadata.yaml
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

Flight controllers (vehicle firmware):

```bash
./scripts/build_ap.sh AF-F4_nano copter
./scripts/build_ap.sh AF-H7_nano copter
./scripts/build_ap.sh AF-F7_mini copter
./scripts/build_ap.sh AF-H7E copter
```

DroneCAN peripheral (AP_Periph firmware — pass `AP_Periph` as the target):

```bash
./scripts/build_ap.sh AP-RTK_dual AP_Periph
```

The bootloader is built automatically on first run if not present. ArduPilot builds need the standard ArduPilot Python packages (`pymavlink`, `empy==3.3.4`, `intelhex`, …); the **`intelhex`** module is required for the combined `*_with_bl.hex` to be generated.

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

ls releases/AP-RTK_dual/ardupilot/
# AP_Periph.bin  AP_Periph.apj  AP_Periph_with_bl.hex  AP-RTK_dual_bl.bin  ...
```

## Publishing a Release

```bash
# Create a GitHub Release with firmware zips for all boards
./scripts/release.sh v1.0.0
```

## Flashing

Flight controllers:

| Method | File | When |
|--------|------|------|
| STLink / DFU | `*_with_bl.hex` | First flash (includes bootloader) |
| Mission Planner | `.apj` | ArduPilot OTA update |
| BF Configurator | `.hex` | Betaflight update |

DroneCAN peripherals (e.g. AP-RTK dual — no USB DFU):

| Method | File | When |
|--------|------|------|
| STLink / SWD | `AP_Periph_with_bl.hex` | First flash (bootloader + app, at `0x08000000`) |
| Mission Planner → DroneCAN | `AP_Periph.bin` | Firmware update over CAN |

## How It Works

Board definitions live in `boards/`, separate from firmware source. The `sync_ap_board.sh` script creates relative symlinks into the ArduPilot source tree so the build system can find them.

Updating firmware source is independent of board configs:

```bash
cd firmware/ardupilot && git pull
```

## License

Hardware design files are proprietary to novaX-ALUX.
Firmware definitions follow their respective upstream licenses (GPLv3).
