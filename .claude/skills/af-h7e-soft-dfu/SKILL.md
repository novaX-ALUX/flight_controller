---
name: af-h7e-soft-dfu
description: AF-H7E(novaX, STM32H753 클론) 버튼·전원재인가 없는 순수 소프트웨어 DFU 진입/복원. USB MAVLink 명령(param4=99+매직 42,24,71)으로 boot_to_dfu가 BOOT_ADD0 옵션바이트 커밋+NVIC_SystemReset→0483:df11 진입. "H753 DFU","소프트웨어 DFU","버튼없이 DFU","boot_to_dfu","BOOT_ADD0","df11 진입","DFU 복원" 트리거.
---

# AF-H7E 소프트웨어 DFU 스킬 (novaX, STM32H753)

2026-07-07 실측 확정. **버튼·전원재인가 없이 USB 명령 하나로** AF-H7E(H753)를 `0483:df11 "DFU in FS Mode"`로 진입시키고, USB DFU로 다시 복원한다.

## 철칙 — 이걸 몰라서 며칠 헤맸다. 먼저 읽어라.
1. **param4 DFU 명령은 반드시 매직 시퀀스와 함께 보낸다.** ArduPilot `handle_preflight_reboot`(GCS_Common.cpp)의 param4 디버그 핸들러(96~100, DFU=99 포함)는 전부 `if(param1==42 && param2==24 && param3==71)` 가드 안에 있다. **param1=42, param2=24, param3=71, param4=99** 로 보내야 `boot_to_dfu()`가 호출된다. param1=1(일반 리붓코드)로 보내면 boot_to_dfu는 **호출조차 안 되고** 그냥 일반 리붓만 한다(옛 오진: "옵션쓰기 실패"는 사실 boot_to_dfu 미호출이었음).
2. **param4=97은 쓰지 마라(진단용도라도).** `AP_MAVLINK_FAILURE_CREATION_ENABLED`가 켜진 빌드는 param4=97을 "Creating long loop"로 선점한다(내 커스텀 97 핸들러는 그 뒤라 도달 못 함). 커스텀 디버그 명령은 101+ 등 안 쓰는 값으로.
3. **`--start`는 리셋이 아니라 점프다.** DFU에서 옵션바이트 복원 후 `STM32_Programmer_CLI --start 0x08000000` 하면 USB가 dark로 남는다(H7 점프시 USB 상태 누수). 앱 USB(COM)를 살리려면 **POR = 케이블 뽑았다 재삽입** 1회 필요.
4. **이 셋업에선 SWD CLI가 안 되고 USB DFU CLI는 된다.** `STM32_Programmer_CLI -c port=SWD`는 "Unable to get core ID"로 실패. 하지만 `-c port=USB1`(DFU 모드)은 정상. 복원/옵션바이트는 USB DFU로 한다(SWD 배선 불필요).
5. 추측 금지. 프로토콜/레지스터는 RM0433·ST HAL로 확인. WSL↔Windows 실행은 [[wsl-windows-claude-bridge]] 방식(윈도우 파이썬을 powershell.exe interop로).

## 대상 / 상수
- 보드: AF-H7E = CUAV V6X 클론, **STM32H753** (Device ID 0x450), APJ board_id **6202**, BOOT0 핀 low 고정.
- ROM DFU: **VID 0x0483 / PID 0xDF11** "DFU in FS Mode".
- **BOOT_CM7_ADD0 인코딩 = 부트주소 >> 16** (16비트 필드, 64KB 단위). `0x1FF0`=`0x1FF00000`(ST 시스템 ROM=DFU), `0x0800`=`0x08000000`(앱 뱅크1). CubeProgrammer는 `BOOT_CM7_ADD0: 0x0800 (0x08000000)`처럼 둘 다 표시.
- 전제: RDP Level 0/1 (Level2면 BOOT_ADD0 무시), 서명 펌웨어 아님(AP_SIGNED_FIRMWARE면 DFU 거부), hwdef `ENABLE_DFU_BOOT 1`.

## A. 소프트웨어 DFU 진입 (앱 → ROM df11)
호스트에서 USB MAVLink로 아래 명령 전송(스크립트 `scripts/enter_dfu.py`):
```
MAV_CMD_PREFLIGHT_REBOOT_SHUTDOWN(246), param1=42, param2=24, param3=71, param4=99
```
펌웨어 `boot_to_dfu()`(아래)가 BOOT_ADD0=0x1FF00000 커밋 → 실제 커밋 확인되면 USB클럭 클리어 → `NVIC_SystemReset()` → ROM 콜드부팅 → **`0483:df11` 열거.** 앱 COM은 사라진다(정상). 파이썬이 던지는 `SerialException(장치가 명령을 인식하지 않습니다)`는 리셋으로 COM이 사라진 것 = 성공 신호.

진입 확인(Windows):
```powershell
Get-CimInstance Win32_PnPEntity -Filter "DeviceID LIKE '%VID_0483&PID_DF11%'"  # 있으면 성공
```

## B. 복원 (ROM df11 → 앱)
앱 펌웨어는 플래시(0x08000000)에 그대로 있다. **부트주소만 되돌리면** 리셋 시 앱이 부팅된다.
```
STM32_Programmer_CLI -c port=USB1 -ob BOOT_CM7_ADD0=0x0800
```
→ "Option Bytes successfully programmed". 그다음 **USB 케이블 재삽입(POR)** → ArduPilot 앱 COM 복귀.
읽기 검증: `STM32_Programmer_CLI -c port=USB1 -ob displ` → `BOOT_CM7_ADD0: 0x800 (0x8000000)`.
CLI 경로(Windows): `C:\Program Files\STMicroelectronics\STM32Cube\STM32CubeProgrammer\bin\STM32_Programmer_CLI.exe` (v2.21.0 확인).

## C. 펌웨어 구현 (앱만 수정, 부트로더 무관)
`repos/flight_controller/firmware/ardupilot/` 기준:
| 파일 | 역할 |
|---|---|
| `libraries/AP_HAL_ChibiOS/Util.cpp` `boot_to_dfu()` | H7: `set_boot_address0(0x1FF00000)` 커밋 → 읽어서 `(BOOT_CUR&0xFFFF)==0x1FF0` 확인된 경우만 `RCC->AHB1ENR &= ~(USB1OTGHSEN\|USB2OTGFSEN)` → `NVIC_SystemReset()`. 실패면 `set_boot_address0(0x08000000)` 복원+앱 잔류(브릭·헛리붓 없음). |
| `libraries/AP_HAL_ChibiOS/hwdef/common/flash.c` `stm32_flash_set_boot_address0()` | 옵션바이트 쓰기. **OPTSTART 전 양 뱅크 idle 대기 필수**: `while(SR1&(BSY\|QW\|WBNE) \|\| SR2&(...))` — 러닝 앱의 계류 플래시 쓰기가 OPTSTART를 조용히 막는 것 방지(검증된 `stm32_flash_wait_idle`와 동일 플래그). 시퀀스: 양뱅크 idle → CCR1/CCR2·OPTCCR 에러클리어 → OPTKEYR 언락 → BOOT_PRG 스테이징 → idle 재확인 → OPTSTART → OPT_BUSY 대기 → OPTCHANGEERR 검증 → OPTLOCK. |
| `libraries/GCS_MAVLink/GCS_Common.cpp` `handle_preflight_reboot` | 매직 시퀀스 가드 + `#if HAL_ENABLE_DFU_BOOT` param4==99 → `hal.util->boot_to_dfu()`. AP_SIGNED_FIRMWARE면 거부. |
| `boards/AF-H7E/ardupilot/hwdef.dat` | `ENABLE_DFU_BOOT 1`, board_id 6202. |
| `Tools/AP_Bootloader/AP_Bootloader.cpp` main() | **self-heal(자동부팅)**: `flash_init()` 직후 `#if defined(STM32H7)` — `(FLASH->BOOT_CUR&0xFFFF)==0x1FF0`이면 `stm32_flash_set_boot_address0(0x08000000)` 복원 → 커밋 확인 시 USB클럭 클리어+`NVIC_SystemReset()`. DFU leave 점프를 깨끗한 콜드부팅으로 전환(E 참조). 정상부팅엔 no-op. |

RM0433 근거: SYSRESETREQ/소프트리셋은 풀 시스템 리셋 → BOOT_ADD0 매 리셋 재래치(POR 한정 아님). 단 옵션바이트는 소프트리셋으로 재로드 안 되므로 **리셋 전에** OPTSTART 커밋 필수. `system.cpp __entry_hook`(0x1FF09800 점프)은 이 fork에서 dead code(crt0가 `__early_init`만 호출) — 소프트 점프 경로는 USB dark라 안 씀.

## D. 빌드·OTA (WSL↔Windows)
- 빌드: `ardupilot-linux-build` 스킬. `scripts/build_ap.sh AF-H7E copter`, gcc-10.2.1 PATH, `NOVAX_VERSION` 스탬프. 산출물 `releases/AF-H7E/ardupilot/arducopter.apj`.
- **빌드 후 apj를 Windows로 복사할 때 반드시 md5·이미지 문자열로 검증** (예전에 stale 사본을 구워서 헛테스트함):
  ```python
  import json,zlib,base64
  raw=zlib.decompress(base64.b64decode(json.load(open("x.apj"))['image']))
  print(len(raw), hex(zlib.crc32(raw)&0xffffffff), b"찾을문자열" in raw)
  ```
- OTA: 윈도우 파이썬(`C:\Users\jisan\AppData\Local\Programs\Python\Python313\python.exe`)으로 `serial_update.py COM<n> <apj>` (스테이징: `C:\Users\jisan\claude_hw\`). board_id 6202 일치 시 SWD 없이 USB OTA 가능.

## E. DFU에서 펌웨어 hex 플래시 → 자동부팅 (검증됨 2026-07-07, v0.2.9)
소프트 DFU 진입(A) 후 `_with_bl.hex`(부트로더+앱 병합, base 0x08000000)를 굽고 **재연결·수동복원 없이 앱으로 자동부팅**:
1. **진입**: `scripts/enter_dfu.py` (param4=99+매직) → BOOT_ADD0=0x1FF00000 + df11.
2. **플래시(leave 포함)**: `flash_dfu.py <with_bl.hex>` (parts-catalog/tools, pyusb DfuSe: erase→write→**read-back verify**→leave). **`--no-leave` 쓰지 말 것**(leave 필요). **호스트에서 BOOT_ADD0 미리 쓰지 말 것**(self-heal discriminator 무력화). 실측 2MB erase+write+verify 39s.
3. **자동부팅**: DFU leave는 시스템 리셋이 아니라 0x08000000으로 **점프**(AN3156, DFU엔 리셋 명령 없음) → 갓 구운 **self-heal 부트로더**가 `BOOT_CUR&0xFFFF==0x1FF0` 감지 → BOOT_ADD0=0x08000000 복원 + `NVIC_SystemReset()` → 깨끗한 콜드부팅으로 앱 USB 정상 열거. **케이블 재삽입 불필요.** (self-heal 없는 옛 부트로더 상태에서도 됨 — leave가 **새로 flash된** self-heal 부트로더로 점프하므로.)

**⚠️ 빌드 함정(self-heal 반영 시):** `build_ap.sh`는 `Tools/bootloaders/<board>_bl.bin`이 **없을 때만** 부트로더를 빌드함. 부트로더 소스(AP_Bootloader.cpp) 수정 후엔 `rm Tools/bootloaders/AF-H7E_bl.{bin,hex}` → `python3 Tools/scripts/build_bootloaders.py AF-H7E` 강제 재빌드 → 앱 재빌드해야 `_with_bl.hex`에 반영됨.

**⚠️ flash_dfu.py는 원래 F4 전용 가정이라 H7에서 2곳을 고쳐야 동작(반영 완료):**
- **섹터맵**: `get_string(dev,4)` 하드코딩 인덱스 → **@Internal Flash 디스크립터 스캔**(H7 iInterface=6, `/0x08000000/16*128Kg`). 안 고치면 F4 fallback맵으로 erase 헛발질 → `write fail`.
- **전송크기**: `XFER=2048` 하드코딩 → DFU functional desc의 **`wTransferSize` 읽어 사용**(F4 ROM=2048, **H7 ROM=1024**). 2048 보내면 write가 `DFU status 2`로 거부. 웹 `dfu.ts`(WebUSB)는 이미 1024라 무관.
- **DFU 에러 복구**: 실패한 플래시가 df11을 dfuERROR에 가두면 이후 flash_dfu/CubeProgrammer 모두 Pipe/read 에러 → `scripts/dfu_reset.py`(ABORT+CLRSTATUS+libusb `dev.reset()`) 또는 물리 재삽입(BOOT_ADD0=0x1FF0이라 재삽입=fresh ROM DFU).
- WSL 실행: Windows 파이썬은 pyusb+libusb_package 필요(설치돼 있음). hex/스크립트는 `C:\Users\jisan\claude_hw\`로 스테이징 후 powershell interop.

## 스크립트
- `scripts/enter_dfu.py <COM>` — 매직 시퀀스 + param4=99 전송(진입). 검증됨.
- `scripts/dfu_reset.py` — 갇힌 df11 DFU 상태 초기화(ABORT+CLRSTATUS+USB reset).
- 플래시는 `parts-catalog/tools/flash_dfu.py <with_bl.hex> --no-leave`(H7 fix 반영본).
- 복원은 위 B의 `STM32_Programmer_CLI -c port=USB1 -ob BOOT_CM7_ADD0=0x0800`.

## 호스트 툴 TODO (제품화)
웹/CLI DFU 플래시 파이프라인에 통합: ① Update 탭에서 param4=99+매직으로 소프트 DFU 자동 진입, ② 플래시 후 `BOOT_ADD0=0x08000000` 자동 복원(`dfu.ts`/`flash_dfu.py`에 OB write — 안 하면 매 리셋 ROM DFU 재진입). 관련: `web-fw-update`·`dfu-flash` 스킬.
