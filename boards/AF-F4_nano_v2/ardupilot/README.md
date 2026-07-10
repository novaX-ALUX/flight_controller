# AF-F4 nano v2 ArduPilot Board Config

This directory is the single source of truth for the `AF-F4_nano_v2` ArduPilot board definition.

Key hardware mapping:

- MCU: `STM32F405xx`, 8 MHz external oscillator, 1024 KB flash
- Board ID: `6204` (its own id — the AF-F4 nano family's `6203` firmware is not compatible)
- IMU: `ICM-42688-P` on `SPI1`, CS `PC2`
- Barometer: `DPS368` on `I2C1` at `0x76`
- GPS: `MAX-M10S` on `USART1`
- Compass: `QMC5883P` on `I2C1` (external, on the GPS module)
- SD card: `SPI3`, CS `PC1`
- Motors: 6 outputs (`PC6`, `PC7`, `PC8`, `PC9`, `PA15`, `PA8`)
- No onboard OSD chip

Notes:

- `PA14` is kept as `SWCLK` so SWD recovery stays available; only `PB9` drives the status LED.
- `BATT_AMP_PERVLT` defaults to `17.0` for the 184 A sensor and is expected to be calibrated
  per unit.

Layout:

- `hwdef.dat`: main flight-controller hardware definition
- `hwdef-bl.dat`: bootloader hardware definition
- `defaults.parm`: board-specific default parameters (GPS type, ESC protocol, compass)

Both `hwdef.dat` and `hwdef-bl.dat` set `ENABLE_DFU_BOOT 1`. The app's `Util::boot_to_dfu()`
stores a flag in persistent data and reboots; the bootloader's `__entry_hook()` reads it and
jumps to the STM32F4 system memory at `0x1FFF0000`, which enumerates as USB DFU. The hook is
compiled only when the bootloader is built with `ENABLE_DFU_BOOT`, so both files must set it.

Build flow:

1. Run `scripts/sync_ap_board.sh AF-F4_nano_v2`
2. Run `scripts/build_ap.sh AF-F4_nano_v2 copter`
3. Collect release artifacts from `releases/AF-F4_nano_v2/ardupilot/`
