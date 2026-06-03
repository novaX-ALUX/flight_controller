# AP-RTK dual — ArduPilot AP_Periph Board Config

DroneCAN RTK GNSS + compass peripheral, based on the CUAV C-RTK2-HP design,
adapted for the novaX "AP-RTK dual" clone board.

Key hardware mapping:

- MCU: `STM32F412Rx`
- GNSS: moving-baseline capable receiver on `USART2` (DroneCAN GPS type 25, NMEA Unicore)
- Compass: `RM3100` on `I2C3` at `0x20`
- CAN: `CAN1` (DroneCAN node)
- Firmware: **AP_Periph** (peripheral firmware, not a vehicle firmware)
- DroneCAN node name: `AP-RTK dual` (`CAN_APP_NODE_NAME`)
- Board ID: `6201` (novaX-ALUX reserved range 6200–6209)

Clone-specific changes vs CUAV C-RTK2-HP:

- `APJ_BOARD_ID` 1085 → **6201**. Distinct firmware identity; the flight
  controller still recognises the GPS/compass over DroneCAN by message + node
  id, *not* by board id.
- DroneCAN node name → **"AP-RTK dual"**.
- **RM3100 X/Y axes are reversed** on this PCB, giving a constant 180° heading
  offset vs the CUAV board. Corrected in firmware with `ROTATION_YAW_90`
  (CUAV's `ROTATION_YAW_270` + 180°). Confirmed on hardware.

Layout:

- `hwdef.dat`: AP_Periph hardware definition
- `hwdef-bl.dat`: bootloader hardware definition

Build:

```bash
scripts/build_ap.sh AP-RTK_dual AP_Periph
```

Flash (this board has no USB DFU):

| File | When |
|------|------|
| `AP-RTK_dual_with_bl.hex` | **First flash** — combined bootloader + app, one-shot via ST-Link / SWD (PA13/PA14), e.g. STM32CubeProgrammer |
| `AP_Periph.apj` / `AP_Periph.bin` | Update over DroneCAN (Mission Planner SLCAN → Update firmware) once the bootloader is present |
| `AP-RTK_dual_bl.bin` + `AP_Periph.bin` | Alternative two-step SWD flash: bootloader at `0x08000000`, app at `0x08010000` |

End users only flash the prebuilt firmware — the X/Y compass fix and the node
name are baked in; there are no parameters to set on the module.
