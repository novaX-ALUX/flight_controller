# AF-F4 nano ArduPilot Board Config

This directory is the single source of truth for the `AF-F4_nano` ArduPilot board definition.

Key hardware mapping:

- MCU: `STM32F405xx`
- GPS: `MAX-M10S` on `USART1`
- Compass: `QMC5883P` on `I2C1` at `0x2C`
- Barometer: `SPL06` on `I2C1` at `0x76`
- IMU: `Invensensev3` on `SPI1`
- OSD: `AT7456E` on `SPI2`
- SD card: `SPI3`

Layout:

- `hwdef.dat`: main flight-controller hardware definition
- `hwdef-bl.dat`: bootloader hardware definition
- `defaults.parm`: board-specific default parameters (GPS type, ESC protocol, compass)

Build flow:

1. Run `scripts/sync_ap_board.sh AF-F4_nano`
2. Run `scripts/build_ap.sh AF-F4_nano copter`
3. Collect release artifacts from `releases/AF-F4_nano/ardupilot/`
