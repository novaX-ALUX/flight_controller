---
name: af-h7e-soft-dfu
description: AF-H7E (novaX, STM32H753 clone) buttonless software DFU entry / recovery. A USB MAVLink command (param4=99 + magic 42,24,71) makes boot_to_dfu commit the BOOT_ADD0 option byte and NVIC_SystemReset into 0483:df11. Triggers on "H753 DFU", "software DFU", "buttonless DFU", "boot_to_dfu", "BOOT_ADD0", "df11 entry", "DFU recovery".
---

# AF-H7E software DFU (novaX, STM32H753)

Hardware-verified 2026-07. With a single USB command — no button, no power cycle — the AF-H7E
(H753) enters `0483:df11 "DFU in FS Mode"`, and is recovered again over USB DFU.

## Ground rules — read first (these cost days to learn).
1. **The param4 DFU command MUST include the magic sequence.** ArduPilot's `handle_preflight_reboot`
   (GCS_Common.cpp) keeps every param4 debug handler (96–100, incl. DFU=99) behind
   `if (param1==42 && param2==24 && param3==71)`. Send **param1=42, param2=24, param3=71, param4=99**
   or `boot_to_dfu()` is never called (param1=1 just does a normal reboot — the old "option write
   failed" diagnosis was really "boot_to_dfu was never invoked").
2. **Do not use param4=97 (even for diagnostics).** Builds with `AP_MAVLINK_FAILURE_CREATION_ENABLED`
   claim param4=97 for "Creating long loop" first. Use an unused value (101+) for custom debug commands.
3. **`--start` is a jump, not a reset.** After restoring the option byte, `STM32_Programmer_CLI
   --start 0x08000000` leaves USB dark on H7 (state leaks across the jump). One POR (unplug/replug)
   is needed to bring the app USB (COM) back — or use the bootloader self-heal (section E).
4. **On this setup SWD CLI fails but USB-DFU CLI works.** `STM32_Programmer_CLI -c port=SWD` fails
   with "Unable to get core ID"; `-c port=USB1` (DFU mode) is fine. Do recovery / option bytes over
   USB DFU (no SWD wiring needed).
5. No guessing. Verify protocol/registers against RM0433 and the ST HAL. Run Windows Python from
   WSL via powershell.exe interop (the board's USB is on Windows).

## Target / constants
- Board: AF-H7E = CUAV V6X clone, **STM32H753** (Device ID 0x450), APJ board_id **6202**, BOOT0 pin tied low.
- ROM DFU: **VID 0x0483 / PID 0xDF11** "DFU in FS Mode".
- **BOOT_CM7_ADD0 encoding = boot address >> 16** (16-bit field, 64 KB granularity). `0x1FF0` =
  `0x1FF00000` (ST system ROM = DFU), `0x0800` = `0x08000000` (app, flash bank 1). CubeProgrammer
  shows both: `BOOT_CM7_ADD0: 0x0800 (0x08000000)`.
- Preconditions: RDP Level 0/1 (Level 2 ignores BOOT_ADD0); not signed firmware (AP_SIGNED_FIRMWARE
  refuses DFU); hwdef `ENABLE_DFU_BOOT 1`.

## A. Enter software DFU (app → ROM df11)
Send this over USB MAVLink from the host (`scripts/enter_dfu.py`):
```
MAV_CMD_PREFLIGHT_REBOOT_SHUTDOWN(246), param1=42, param2=24, param3=71, param4=99
```
Firmware `boot_to_dfu()` (below) commits BOOT_ADD0=0x1FF00000; only if the readback confirms it
does it clear the USB clocks and `NVIC_SystemReset()` → the ROM cold-boots → **`0483:df11` enumerates.**
The app COM disappears (expected). The `SerialException` pymavlink throws is the COM going away on
reset = success signal.

Confirm entry (Windows):
```powershell
Get-CimInstance Win32_PnPEntity -Filter "DeviceID LIKE '%VID_0483&PID_DF11%'"  # present = success
```

## B. Recovery (ROM df11 → app)
The app firmware is still in flash at 0x08000000. **Just restore the boot address** and a reset boots the app.
```
STM32_Programmer_CLI -c port=USB1 -ob BOOT_CM7_ADD0=0x0800
```
→ "Option Bytes successfully programmed", then **re-plug USB (POR)** → the ArduPilot app COM returns.
Read-verify: `STM32_Programmer_CLI -c port=USB1 -ob displ` → `BOOT_CM7_ADD0: 0x800 (0x8000000)`.
CLI path (Windows): `...\STM32Cube\STM32CubeProgrammer\bin\STM32_Programmer_CLI.exe` (tested v2.21.0).

## C. Firmware implementation
Under `repos/flight_controller/firmware/ardupilot/`:
| File | Role |
|---|---|
| `libraries/AP_HAL_ChibiOS/Util.cpp` `boot_to_dfu()` | H7: commit `set_boot_address0(0x1FF00000)` → only if the readback `(BOOT_CUR&0xFFFF)==0x1FF0` clear the USB OTG clocks and `NVIC_SystemReset()`. If it did not commit, restore `set_boot_address0(0x08000000)` and stay in the app (no brick, no pointless reboot). |
| `libraries/AP_HAL_ChibiOS/hwdef/common/flash.c` `stm32_flash_set_boot_address0()` | Option-byte write. **Must wait for BOTH banks idle before OPTSTART**: `while (SR1&(BSY\|QW\|WBNE) \|\| SR2&(...))` — a running app's queued flash writes silently block OPTSTART (same flags as the proven `stm32_flash_wait_idle`). Sequence: both-bank idle → clear CCR1/CCR2 + OPTCCR errors → OPTKEYR unlock → stage BOOT_PRG → re-check idle → OPTSTART → wait OPT_BUSY → verify OPTCHANGEERR → OPTLOCK. |
| `libraries/GCS_MAVLink/GCS_Common.cpp` `handle_preflight_reboot` | magic-sequence guard + `#if HAL_ENABLE_DFU_BOOT` param4==99 → `hal.util->boot_to_dfu()`. Refused if AP_SIGNED_FIRMWARE. |
| `Tools/AP_Bootloader/AP_Bootloader.cpp` main() | **self-heal (auto-boot)**: right after `flash_init()`, `#if defined(STM32H7)` — if `(FLASH->BOOT_CUR&0xFFFF)==0x1FF0` restore `stm32_flash_set_boot_address0(0x08000000)`, then on committed readback clear the USB clocks + `NVIC_SystemReset()`. Turns the DFU-leave jump into a clean cold boot (see E). No-op on a normal boot. |
| `boards/AF-H7E/ardupilot/hwdef.dat` | `ENABLE_DFU_BOOT 1`, board_id 6202. |

RM0433 basis: SYSRESETREQ / soft reset is a full system reset → BOOT_ADD0 is re-latched on every
reset (not POR-only). But option bytes are NOT reloaded by a soft reset, so OPTSTART must commit
**before** the reset. `system.cpp __entry_hook` (jump to 0x1FF09800) is dead code in this fork
(crt0 only calls `__early_init`) — the software-jump path is USB-dark and unused.

## D. Build & OTA
- Build: use the `ardupilot-linux-build` skill. `scripts/build_ap.sh AF-H7E copter`, gcc-10.2.1 on
  PATH, `NOVAX_VERSION` stamp. Output `releases/AF-H7E/ardupilot/arducopter.apj`.
- **When copying the apj to Windows, always verify by md5 + an image string** (a stale copy was
  flashed once and gave a false test):
  ```python
  import json, zlib, base64
  raw = zlib.decompress(base64.b64decode(json.load(open("x.apj"))['image']))
  print(len(raw), hex(zlib.crc32(raw) & 0xffffffff), b"a-string-to-find" in raw)
  ```
- OTA: run `serial_update.py COM<n> <apj>` with the Windows Python; stage files in a Windows folder
  first. With matching board_id 6202, USB OTA works with no SWD.

## E. Flash a hex over DFU → auto-boot (verified 2026-07, v0.2.9)
After entering software DFU (A), flash `_with_bl.hex` (bootloader + app, base 0x08000000) and the
app **auto-boots with no re-plug and no manual restore**:
1. **Enter**: `scripts/enter_dfu.py` (param4=99 + magic) → BOOT_ADD0=0x1FF00000 + df11.
2. **Flash (with leave)**: `flash_dfu.py <with_bl.hex>` (parts-catalog/tools, pyusb DfuSe: erase →
   write → **read-back verify** → leave). **Do NOT pass `--no-leave`** (leave is required). **Do NOT
   pre-write BOOT_ADD0 on the host** (it defeats the self-heal discriminator). Measured 2 MB
   erase+write+verify ≈ 39 s.
3. **Auto-boot**: the DFU leave is a **jump** to 0x08000000 (AN3156 — DFU has no reset request), not
   a reset → the freshly-flashed **self-heal bootloader** sees `BOOT_CUR&0xFFFF==0x1FF0`, restores
   BOOT_ADD0=0x08000000, `NVIC_SystemReset()` → clean cold boot, app USB enumerates. **No re-plug.**
   (Works even from an old bootloader, because the leave jumps into the *newly flashed* self-heal one.)

**⚠️ Build gotcha (when changing the self-heal):** `build_ap.sh` builds the bootloader **only when
`Tools/bootloaders/<board>_bl.bin` is missing**. After editing AP_Bootloader.cpp, force a rebuild:
`rm Tools/bootloaders/AF-H7E_bl.{bin,hex}` → `python3 Tools/scripts/build_bootloaders.py AF-H7E` →
then rebuild the app so `_with_bl.hex` picks it up.

**⚠️ flash_dfu.py assumed F4; two H7 fixes were required (already applied):**
- **Sector map**: `get_string(dev,4)` hardcoded index → **scan the @Internal Flash descriptor**
  (H7 iInterface=6, `/0x08000000/16*128Kg`). Otherwise the F4 fallback map mis-erases → `write fail`.
- **Transfer size**: hardcoded `XFER=2048` → **read `wTransferSize`** from the DFU functional
  descriptor (F4 ROM=2048, **H7 ROM=1024**). Sending 2048 makes the write fail with `DFU status 2`.
  The web `dfu.ts` (WebUSB) already uses 1024, so it is unaffected.
- **DFU error recovery**: a failed flash can leave df11 in dfuERROR (then flash_dfu/CubeProgrammer
  both hit Pipe/read errors) → `scripts/dfu_reset.py` (ABORT + CLRSTATUS + libusb `dev.reset()`), or
  re-plug (with BOOT_ADD0=0x1FF0 a re-plug = a fresh ROM DFU).
- WSL: the Windows Python needs pyusb + libusb_package. Stage the hex/scripts in a Windows folder,
  then run via powershell interop.

## Scripts
- `scripts/enter_dfu.py <COM>` — send the magic sequence + param4=99 (enter DFU). Verified.
- `scripts/dfu_reset.py` — clear a stuck df11 DFU state (ABORT + CLRSTATUS + USB reset).
- Flash with `parts-catalog/tools/flash_dfu.py <with_bl.hex>` (the H7-fixed version).
- Recover with the section-B `STM32_Programmer_CLI -c port=USB1 -ob BOOT_CM7_ADD0=0x0800`.

## Host-tool TODO (productization)
Fold into the web/CLI DFU pipeline: (1) auto-enter software DFU from the Update tab (param4=99 +
magic), (2) auto-restore `BOOT_ADD0=0x08000000` after flashing (an OB write in `dfu.ts`/`flash_dfu.py`
— otherwise every reset re-enters ROM DFU). Related: `web-fw-update`, `dfu-flash` skills.
