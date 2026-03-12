# novax_H743_V1 Flight Controller

STM32H743VIH6-based flight controller, compatible with ArduPilot and Betaflight.

## Specifications

| Item | Detail |
|------|--------|
| MCU | STM32H743VIH6 (480MHz, 2MB Flash, TFBGA-100) |
| IMU | Dual ICM-42688-P (SPI1 + SPI4) |
| Barometer | DPS310 (I2C2, 0x76) |
| Magnetometer | IST8310 (I2C2, 0x0E) |
| OSD | AT7456E / MAX7456 compatible (SPI2) |
| CAN | FDCAN1 + TJA1051TK/3 transceiver |
| SD Card | SDMMC1 4-bit |
| USB | Type-C (OTG_FS) |
| Motor Outputs | 10 PWM (DShot on M1-M4) |
| UARTs | 7 (USART1/2/3/6, UART4/7/8) |
| LED Strip | WS2812 (PA8) |
| Voltage Sense | R14=10K / R24=1K (Scale 11.0) |

## Pin Mapping

### Motor Outputs

| Motor | Pin | Timer |
|-------|-----|-------|
| M1 | PB0 | TIM3_CH3 |
| M2 | PB1 | TIM3_CH4 |
| M3 | PA0 | TIM5_CH1 |
| M4 | PA1 | TIM5_CH2 |
| M5 | PA2 | TIM5_CH3 |
| M6 | PA3 | TIM5_CH4 |
| M7 | PD12 | TIM4_CH1 |
| M8 | PD13 | TIM4_CH2 |
| M9 | PD14 | TIM4_CH3 |
| M10 | PD15 | TIM4_CH4 |

### Serial Ports

| Port | TX | RX | Default Function |
|------|----|----|-----------------|
| UART1 | PA9 | PA10 | VTX (SmartAudio) |
| UART2 | PD5 | PD6 | DJI O3 (SBUS RC) |
| UART3 | PD8 | PD9 | ELRS Receiver |
| UART4 | PB9 | PB8 | DJI O3 MSP |
| UART6 | PC6 | PC7 | GPS |
| UART7 | PE8 | PE7 | Spare |
| UART8 | PE1 | PE0 | Spare |

### ADC

| Function | Pin | ADC Channel |
|----------|-----|-------------|
| VBAT | PC0 | ADC1_CH10 |
| Current | PC1 | ADC1_CH11 |
| RSSI | PC5 | ADC1_CH8 |
| Airspeed | PC4 | ADC1_CH4 |
| VBAT2 | PA4 | ADC1_CH18 |
| Current2 | PA7 | ADC1_CH7 |

## Directory Structure

```
├── Hardware/
│   └── H743_FC_V1.0.pdf       # Schematic
├── ArduPilot/
│   ├── hwdef.dat               # Hardware definition
│   ├── hwdef-bl.dat            # Bootloader definition
│   └── defaults.parm           # Default parameters
└── Betaflight/
    └── config.h                # Unified Target config
```

## Building Firmware

### ArduPilot

```bash
git clone --recurse-submodules https://github.com/ArduPilot/ardupilot.git
cd ardupilot

# Copy board files
cp -r <this-repo>/ArduPilot/* libraries/AP_HAL_ChibiOS/hwdef/novax_H743_V1/

# Build bootloader
python3 Tools/scripts/build_bootloaders.py novax_H743_V1

# Build ArduCopter
python3 ./waf configure --board novax_H743_V1
python3 ./waf copter
```

### Betaflight

```bash
git clone https://github.com/betaflight/betaflight.git
cd betaflight
make arm_sdk_install
make configs

# Copy board config
mkdir -p src/config/configs/novax_H743_V1
cp <this-repo>/Betaflight/config.h src/config/configs/novax_H743_V1/

# Build
make CONFIG=novax_H743_V1
```

## Flashing

### First Flash (via STLink / DFU)

Use `arducopter_with_bl.hex` (ArduPilot) or the Betaflight `.hex` file.

### Subsequent Updates

- **ArduPilot**: Use Mission Planner or MAVProxy to upload `.apj` firmware
- **Betaflight**: Use Betaflight Configurator to flash

## License

Hardware design files are proprietary to novaX-ALUX.
Firmware definition files follow their respective upstream licenses (GPLv3).
