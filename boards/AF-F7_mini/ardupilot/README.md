# AF-F7 mini ArduPilot Board Config

Board definition for the AF-F7 mini flight controller — an autopilot-class
board that drives all PWM outputs directly (no IO co-processor).

Key hardware mapping:

- MCU: `STM32F765IIK6` (216MHz, 2MB Flash, UFBGA), 16MHz crystal
- IMU: `ICM-20689` + `ICM-20602` + `BMI055` (gyro/acc), all on `SPI1`
- Barometer: `MS5611` on `SPI4`
- Compass: `IST8310` on `I2C` (internal) + external probe
- FRAM: on `SPI2` (parameter storage)
- CAN: `FDCAN1` + `FDCAN2`
- SD Card: `SDMMC1` 4-bit
- RC input: dedicated RCIN pin `PI5` (all protocols)
- Motor Outputs: 11 (8x FMU_CH + 3x on TIM2)
- Board ID: `6201` (novaX-ALUX reserved range 6200–6209)

Pin mapping was derived from the board netlist (`docs/X5_Autopilot.NET`) and
verified against the STM32F765 UFBGA ballout.

Layout:

- `hwdef.dat`: main flight-controller hardware definition
- `hwdef-bl.dat`: bootloader hardware definition
- `defaults.parm`: board-specific default parameters (frame, battery, GPS, CAN)

Build:

```bash
scripts/build_ap.sh AF-F7_mini copter
```

Verify before flight:

- IMU and compass **rotations** are provisional — confirm against the physical
  chip placement on the bench.
- Battery voltage/current scaling uses standard power-module values
  (`18.0` / `24.0`) — confirm against the shipped power module.
