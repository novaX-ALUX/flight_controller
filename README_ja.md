# novaX フライトコントローラー

[English](README.md) | [한국어](README_ko.md) | [中文](README_zh.md)

novaX フライトコントローラー向けのボード定義、ビルドスクリプト、ファームウェアリリース。

## 対応ボード

| ボード | MCU | IMU | 気圧計 | コンパス | GPS | ファームウェア |
|--------|-----|-----|--------|----------|-----|----------------|
| novaX_F405 | STM32F405 | ICM-42688-P | SPL06 | QMC5883P (外付け) | MAX-M10S | ArduPilot / Betaflight |
| novaX_H743_V1 | STM32H743 | デュアル ICM-42688-P | DPS310 | IST8310 (内蔵) | - | ArduPilot / Betaflight |

## リポジトリ構成

```
├── firmware/
│   ├── ardupilot/              # ArduPilot ソース (git submodule)
│   └── betaflight/             # Betaflight ソース (git submodule)
├── boards/
│   ├── novaX_F405/
│   │   ├── ardupilot/          # hwdef.dat, hwdef-bl.dat, defaults.parm
│   │   ├── betaflight/         # config.h
│   │   └── docs/               # 回路図
│   └── novaX_H743_V1/
│       ├── ardupilot/          # hwdef.dat, hwdef-bl.dat, defaults.parm
│       ├── betaflight/         # config.h
│       └── docs/               # 回路図
├── scripts/
│   ├── sync_ap_board.sh        # ボード定義を AP ソースツリーへシンボリックリンク
│   ├── build_ap.sh             # 構成 + ビルド + パッケージ化 (ArduPilot)
│   ├── build_bf.sh             # ビルド + パッケージ化 (Betaflight)
│   └── package_fw.sh           # ファームウェア成果物を releases/ に収集
├── releases/                   # ローカルビルド出力 (gitignored)
│   └── <board>/
│       ├── ardupilot/          # .apj, .hex, bootloader
│       └── betaflight/         # .hex, .bin
└── GitHub Releases             # 公開ファームウェア zip
```

## はじめに

### クローン

```bash
git clone --recurse-submodules --shallow-submodules https://github.com/novaX-ALUX/flight_controller.git
cd flight_controller
```

### ArduPilot ビルド

```bash
./scripts/build_ap.sh novaX_F405 copter
./scripts/build_ap.sh novaX_H743_V1 copter
```

ブートローダーは初回実行時に存在しなければ自動でビルドされます。

### Betaflight ビルド

```bash
# ARM ツールチェーンのインストール (初回のみ、GCC 13.3.1 が必要)
cd firmware/betaflight && make arm_sdk_install && cd ../..

# ビルド
./scripts/build_bf.sh novaX_F405
./scripts/build_bf.sh novaX_H743_V1
```

### 出力

ファームウェア成果物は `releases/<board>/` に収集されます:

```bash
ls releases/novaX_F405/ardupilot/
# arducopter.apj  arducopter_with_bl.hex  novaX_F405_bl.bin  ...

ls releases/novaX_H743_V1/betaflight/
# betaflight_novaX_H743_V1.hex  ...
```

## リリース公開

```bash
# 全ボードのファームウェア zip を含む GitHub Release を作成
./scripts/release.sh v1.0.0
```

## 書き込み

| 方法 | ファイル | タイミング |
|------|----------|------------|
| STLink / DFU | `*_with_bl.hex` | 初回書き込み (ブートローダー含む) |
| Mission Planner | `.apj` | ArduPilot OTA 更新 |
| BF Configurator | `.hex` | Betaflight 更新 |

## 仕組み

ボード定義はファームウェアソースから分離されて `boards/` に置かれます。`sync_ap_board.sh` スクリプトが ArduPilot ソースツリーへの相対シンボリックリンクを作成し、ビルドシステムが認識できるようにします。

ファームウェアソースの更新はボード設定とは独立です:

```bash
cd firmware/ardupilot && git pull
```

## ライセンス

ハードウェア設計ファイルは novaX-ALUX 専有です。
ファームウェア定義は各アップストリームのライセンス (GPLv3) に従います。
