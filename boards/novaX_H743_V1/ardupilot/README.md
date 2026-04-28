# novax_H743_V1 ArduPilot Board Config

Board definition for the novax H743 V1 flight controller.

Key hardware mapping:

- MCU: `STM32H743VIH6` (480MHz, 2MB Flash, TFBGA-100)
- IMU: Dual `ICM-42688-P` on `SPI1` + `SPI4`
- Barometer: `DPS310` or `SPA06-003` on `I2C2` at `0x76`
- Compass: `IST8310` on `I2C2` at `0x0E` (internal)
- OSD: `AT7456E` on `SPI2`
- CAN: `FDCAN1` with `TJA1051TK/3`
- SD Card: `SDMMC1` 4-bit
- Motor Outputs: 10 (M1-M4 bidirectional DShot)

Layout:

- `hwdef.dat`: main flight-controller hardware definition
- `hwdef-bl.dat`: bootloader hardware definition
- `defaults.parm`: board-specific default parameters (battery, GPS, ELRS, DJI O3, CAN)

Build:

```bash
scripts/build_ap.sh novax_H743_V1 copter
```
