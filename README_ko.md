# novaX 비행 컨트롤러

[English](README.md) | [中文](README_zh.md) | [日本語](README_ja.md)

novaX 비행 컨트롤러용 보드 정의, 빌드 스크립트, 펌웨어 릴리스.

## 지원 보드

| 보드 | MCU | IMU | 기압계 | 컴퍼스 | GPS | 펌웨어 |
|------|-----|-----|--------|--------|-----|--------|
| novaX_F405 | STM32F405 | ICM-42688-P | SPL06 | QMC5883P (외장) | MAX-M10S | ArduPilot / Betaflight |
| novaX_H743_V1 | STM32H743 | Dual ICM-42688-P | DPS310 | IST8310 (내장) | - | ArduPilot / Betaflight |

## 저장소 구조

```
├── firmware/
│   ├── ardupilot/              # ArduPilot 소스 (git submodule)
│   └── betaflight/             # Betaflight 소스 (git submodule)
├── boards/
│   ├── novaX_F405/
│   │   ├── ardupilot/          # hwdef.dat, hwdef-bl.dat, defaults.parm
│   │   ├── betaflight/         # config.h
│   │   └── docs/               # 회로도
│   └── novaX_H743_V1/
│       ├── ardupilot/          # hwdef.dat, hwdef-bl.dat, defaults.parm
│       ├── betaflight/         # config.h
│       └── docs/               # 회로도
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

```bash
./scripts/build_ap.sh novaX_F405 copter
./scripts/build_ap.sh novaX_H743_V1 copter
```

부트로더는 처음 실행 시 없으면 자동으로 빌드됩니다.

### Betaflight 빌드

```bash
# ARM 툴체인 설치 (최초 1회, GCC 13.3.1 필요)
cd firmware/betaflight && make arm_sdk_install && cd ../..

# 빌드
./scripts/build_bf.sh novaX_F405
./scripts/build_bf.sh novaX_H743_V1
```

### 결과물

펌웨어 산출물은 `releases/<board>/` 에 수집됩니다:

```bash
ls releases/novaX_F405/ardupilot/
# arducopter.apj  arducopter_with_bl.hex  novaX_F405_bl.bin  ...

ls releases/novaX_H743_V1/betaflight/
# betaflight_novaX_H743_V1.hex  ...
```

## 릴리스 게시

```bash
# 모든 보드 펌웨어 zip을 포함한 GitHub Release 생성
./scripts/release.sh v1.0.0
```

## 플래싱

| 방법 | 파일 | 시점 |
|------|------|------|
| STLink / DFU | `*_with_bl.hex` | 최초 플래시 (부트로더 포함) |
| Mission Planner | `.apj` | ArduPilot OTA 업데이트 |
| BF Configurator | `.hex` | Betaflight 업데이트 |

## 동작 원리

보드 정의는 펌웨어 소스와 분리되어 `boards/` 에 위치합니다. `sync_ap_board.sh` 스크립트가 ArduPilot 소스 트리로 상대 심볼릭 링크를 생성하여 빌드 시스템이 이를 인식할 수 있도록 합니다.

펌웨어 소스 업데이트는 보드 설정과 독립적입니다:

```bash
cd firmware/ardupilot && git pull
```

## 라이선스

하드웨어 설계 파일은 novaX-ALUX 독점입니다.
펌웨어 정의는 각각의 업스트림 라이선스 (GPLv3) 를 따릅니다.
