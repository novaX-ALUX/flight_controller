# novaX ArduPilot patches

The `firmware/ardupilot` submodule is pinned to **upstream** ArduPilot, so core-source fixes
that are not expressible as hwdef overlays are kept here as patches and re-applied after a
fresh checkout / `git submodule update` via `scripts/apply_ap_patches.sh`.

## Patches
- **0001-novax-software-dfu-board.patch** — `__early_init()` (bootloader builds with
  `ENABLE_DFU_BOOT`) reads the `boot_to_dfu` persistent flag and jumps to the ST ROM system
  bootloader with a full deinit (disable IRQ / SysTick / NVIC clear / SYSCFG remap / VTOR /
  MSP / CONTROL). Upstream relies on a ChibiOS `CRT0_ENTRY_HOOK` that this pinned ChibiOS
  lacks, so `__entry_hook()` was never called and software DFU never worked. System-memory
  base is per-family: F4=0x1FFF0000, F7=0x1FF00000, H7=0x1FF09800.
- **0002-novax-software-dfu-usb-disconnect.patch** — `Util::boot_to_dfu()` signals a USB
  disconnect (`usbDisconnectBus`) before the reset so the host re-enumerates the ST ROM DFU
  device instead of keeping the stale CDC handle.

## Verified
- **AF-F4_T10_nano (STM32F405): hardware-verified** — MAVLink `param4=99` → board enumerates
  as `0483:df11` cleanly.
- **F7 / H7: built with the fix but NOT hardware-verified** (no boards on hand; they ship
  buttonless). Bench-test via SWD-flash `_with_bl.hex` then a `param4=99` DFU-entry test
  before relying on it for field units.
