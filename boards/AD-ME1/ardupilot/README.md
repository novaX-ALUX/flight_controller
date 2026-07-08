# AD-ME1 (ArduPilot)

Rebrand of the AF-F4_T10_nano build (CADDX-gimbal variant of AF-F4_nano).

- **Hardware:** identical to AF-F4_nano (SpeedyBee F405 V4 base, STM32F405, SPL06 baro, MAX-M10S GPS, QMC5883P compass).
- **Board ID:** `6203` — same as AF-F4_nano / AF-F4_T10_nano, so a board running the matching bootloader accepts this firmware over the normal `.apj` updater.
- **USB product string:** `AD-ME1`.
- **Feature set:** mirrors the custom.ardupilot.org *Selected Features* used for the speedybeef4v4 build, applied via [`AD-ME1_features.inc`](AD-ME1_features.inc), **plus the CADDX gimbal mount**.

## Build

```bash
./scripts/build_ap.sh AD-ME1 copter
```

`AD-ME1_features.inc` is identical to the AF-F4_T10 feature set (custom-build Selected Features + CADDX gimbal).
