# novaX ArduPilot patches

The `firmware/ardupilot` submodule is pinned to **upstream** ArduPilot, so core-source fixes
that are not expressible as hwdef overlays are kept here as patches and re-applied after a
fresh checkout / `git submodule update` via `scripts/apply_ap_patches.sh`.

## Patches
- **0001-novax-software-dfu-board.patch** — buttonless software DFU (MAVLink
  `PREFLIGHT_REBOOT_SHUTDOWN` param4=99, magic 42/24/71 → `Util::boot_to_dfu()`). One
  consolidated patch, two mechanisms by MCU family:
  - **F4 / F7 — software jump.** `board.c __early_init()` (bootloader build) reads the
    `boot_to_dfu` persistent flag and jumps to the ST ROM system bootloader with a full deinit
    (upstream's `system.cpp __entry_hook()` is dead in this pinned ChibiOS). `Util::boot_to_dfu()`
    drops USB D+ (`usbDisconnectBus`) before the reset so the host re-enumerates the ROM DFU
    instead of keeping the stale CDC handle. ROM base: F4=0x1FFF0000, F7=0x1FF00000.
  - **H7 (AF-H7E / H753) — option-byte cold boot.** `Util::boot_to_dfu()` commits
    `BOOT_CM7_ADD0=0x1FF00000` (`flash.c stm32_flash_set_boot_address0`, RM0433 both-bank-idle
    OPTSTART sequence) then `NVIC_SystemReset()` → the ROM cold-boots into USB DFU (0483:DF11).
    After a DFU flash the ST ROM "leave" is a *jump* to 0x08000000 (not a reset), so
    `AP_Bootloader.cpp main()` **self-heals**: if `BOOT_CUR==0x1FF0` it restores
    `BOOT_ADD0=0x08000000` and `NVIC_SystemReset()` → the app cold-boots with clean USB, no
    power cycle. The F4/F7 `board.c` jump is gated `!defined(STM32H7)` (the H753 jump leaves USB
    dark), so it never touches the H7 bootloader binary.

  (This supersedes the former split 0001 board.c / 0002 usb-disconnect patches, which were the
  F4-only jump approach; they are consolidated here alongside the H7 BOOT_ADD0 path.)

## Verified (hardware)
- **AF-F4_T10_nano (STM32F405):** software-jump DFU — `param4=99` → `0483:df11` cleanly.
- **AF-H7E (STM32H753), 2026-07:** BOOT_ADD0 cold-boot DFU entry + `flash_dfu.py`/WebUSB flash +
  bootloader self-heal auto-boot (no power cycle). Full round-trip verified on the bench.
- **F7:** built with the F4/F7 jump path but **not hardware-verified** (no board on hand).
