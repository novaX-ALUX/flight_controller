# novaX 비행 컨트롤러

[English](README.md) | [中文](README_zh.md) | [日本語](README_ja.md)

novaX 비행 컨트롤러 및 DroneCAN 주변장치용 보드 정의, 빌드 스크립트, 펌웨어 릴리스.

## 지원 보드

| 보드 | MCU | IMU | 기압계 | 컴퍼스 | GPS | 펌웨어 |
|------|-----|-----|--------|--------|-----|--------|
| AF-F4 nano | STM32F405 | ICM-42688-P | SPL06 | QMC5883P (외장) | MAX-M10S | ArduPilot / Betaflight |
| AF-H7 nano | STM32H743 | Dual ICM-42688-P | DPS310 | IST8310 (내장) | - | ArduPilot / Betaflight |
| AF-F7 mini&nbsp;‡ | STM32F765 | ICM-20689 + ICM-20602 + BMI055 | MS5611 | IST8310 (내장) | - | ArduPilot |
| AF-H7E&nbsp;‡ | STM32H753 | ICM-42688-P + BMI088 + ICM-20649 | 2× ICP-20100 | RM3100 | - | ArduPilot |
| AP-RTK dual&nbsp;† | STM32F412 | - | - | RM3100 | 듀얼 안테나 RTK (무빙 베이스라인) | ArduPilot AP_Periph |

† **DroneCAN 주변장치** (GPS + 컴퍼스 노드), 비행 컨트롤러가 아님. CUAV C-RTK2-HP 기반, 보드 ID `1085` (CUAV와 동일하게 유지 → DroneCAN OTA 호환).

‡ 중복 IMU를 갖춘 **오토파일럿급** 보드: AF-F7 mini는 PWM 출력을 직접 구동(IO 보조 프로세서 없음)하며, AF-H7E는 STM32F103 IO 보조 프로세서와 이더넷을 갖춘 모듈형 설계입니다. 보드 ID `6201` / `6202` (novaX-ALUX 예약 범위 `6200`–`6209`).

## 저장소 구조

```
├── firmware/
│   ├── ardupilot/              # ArduPilot 소스 (git submodule)
│   └── betaflight/             # Betaflight 소스 (git submodule)
├── boards/
│   ├── AF-F4_nano/             # 비행 컨트롤러
│   │   ├── ardupilot/          # hwdef.dat, hwdef-bl.dat, defaults.parm
│   │   ├── betaflight/         # config.h
│   │   └── docs/               # 회로도
│   ├── AF-H7_nano/             # 비행 컨트롤러
│   │   ├── ardupilot/          # hwdef.dat, hwdef-bl.dat, defaults.parm
│   │   ├── betaflight/         # config.h
│   │   └── docs/               # 회로도
│   ├── AF-F7_mini/             # 비행 컨트롤러 (no IOMCU)
│   │   ├── ardupilot/          # hwdef.dat, hwdef-bl.dat, defaults.parm
│   │   └── docs/               # 회로도 + 네트리스트
│   ├── AF-H7E/                 # 비행 컨트롤러 (modular, Ethernet)
│   │   ├── ardupilot/          # hwdef.dat, hwdef-bl.dat, defaults.parm
│   │   └── docs/               # 회로도 + 네트리스트
│   └── AP-RTK_dual/            # DroneCAN AP_Periph 주변장치 (GPS + 컴퍼스)
│       ├── ardupilot/          # hwdef.dat, hwdef-bl.dat
│       └── metadata.yaml
├── scripts/
│   ├── sync_ap_board.sh        # 보드 설정을 AP 소스 트리에 심볼릭 링크
│   ├── build_ap.sh             # 구성 + 빌드 + 패키징 (ArduPilot)
│   ├── build_bf.sh             # 빌드 + 패키징 (Betaflight)
│   └── package_fw.sh           # 펌웨어 산출물을 releases/ 로 수집
├── releases/                   # 로컬 빌드 출력 (gitignore 처리)
│   └── <board>/
│       ├── ardupilot/          # .apj, .hex, bootloader
│       └── betaflight/         # .hex, .bin
└── GitHub Releases             # 게시된 펌웨어 zip
```

## 시작하기

### 클론

```bash
git clone --recurse-submodules --shallow-submodules https://github.com/novaX-ALUX/flight_controller.git
cd flight_controller
```

### ArduPilot 빌드

비행 컨트롤러 (기체 펌웨어):

```bash
./scripts/build_ap.sh AF-F4_nano copter
./scripts/build_ap.sh AF-H7_nano copter
./scripts/build_ap.sh AF-F7_mini copter
./scripts/build_ap.sh AF-H7E copter
```

DroneCAN 주변장치 (AP_Periph 펌웨어 — 타깃으로 `AP_Periph` 전달):

```bash
./scripts/build_ap.sh AP-RTK_dual AP_Periph
```

부트로더는 처음 실행 시 없으면 자동으로 빌드됩니다. ArduPilot 빌드에는 표준 ArduPilot 파이썬 패키지(`pymavlink`, `empy==3.3.4`, `intelhex` 등)가 필요하며, 결합 `*_with_bl.hex` 생성에는 **`intelhex`** 모듈이 반드시 필요합니다.

### Betaflight 빌드

```bash
# ARM 툴체인 설치 (최초 1회, GCC 13.3.1 필요)
cd firmware/betaflight && make arm_sdk_install && cd ../..

# 빌드
./scripts/build_bf.sh AF-F4_nano
./scripts/build_bf.sh AF-H7_nano
```

### 결과물

펌웨어 산출물은 `releases/<board>/` 에 수집됩니다:

```bash
ls releases/AF-F4_nano/ardupilot/
# arducopter.apj  arducopter_with_bl.hex  AF-F4_nano_bl.bin  ...

ls releases/AP-RTK_dual/ardupilot/
# AP_Periph.bin  AP_Periph.apj  AP_Periph_with_bl.hex  AP-RTK_dual_bl.bin  ...
```

## 릴리스 게시

```bash
# 모든 보드 펌웨어 zip을 포함한 GitHub Release 생성
./scripts/release.sh v1.0.0
```

## 플래싱

비행 컨트롤러:

| 방법 | 파일 | 시점 |
|------|------|------|
| STLink / DFU | `*_with_bl.hex` | 최초 플래시 (부트로더 포함) |
| Mission Planner | `.apj` | ArduPilot OTA 업데이트 |
| BF Configurator | `.hex` | Betaflight 업데이트 |

DroneCAN 주변장치 (예: AP-RTK dual — USB DFU 없음):

| 방법 | 파일 | 시점 |
|------|------|------|
| STLink / SWD | `AP_Periph_with_bl.hex` | 최초 플래시 (부트로더 + 앱, `0x08000000`) |
| Mission Planner → DroneCAN | `AP_Periph.bin` | CAN으로 펌웨어 업데이트 |

## 동작 원리

보드 정의는 펌웨어 소스와 분리되어 `boards/` 에 위치합니다. `sync_ap_board.sh` 스크립트가 ArduPilot 소스 트리로 상대 심볼릭 링크를 생성하여 빌드 시스템이 이를 인식할 수 있도록 합니다.

펌웨어 소스 업데이트는 보드 설정과 독립적입니다:

```bash
cd firmware/ardupilot && git pull
```

## 라이선스

하드웨어 설계 파일은 novaX-ALUX 독점입니다.
펌웨어 정의는 각각의 업스트림 라이선스 (GPLv3) 를 따릅니다.
