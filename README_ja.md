# novaX フライトコントローラー

[English](README.md) | [한국어](README_ko.md) | [中文](README_zh.md)

novaX フライトコントローラーおよび DroneCAN ペリフェラル向けのボード定義、ビルドスクリプト、ファームウェアリリース。

## 対応ボード

| ボード | MCU | IMU | 気圧計 | コンパス | GPS | ファームウェア |
|--------|-----|-----|--------|----------|-----|----------------|
| AF-F4 nano | STM32F405 | ICM-42688-P | SPL06 | QMC5883P (外付け) | MAX-M10S | ArduPilot / Betaflight |
| AF-H7 nano | STM32H743 | デュアル ICM-42688-P | DPS310 | IST8310 (内蔵) | - | ArduPilot / Betaflight |
| AP-RTK dual&nbsp;† | STM32F412 | - | - | RM3100 | デュアルアンテナ RTK (ムービングベースライン) | ArduPilot AP_Periph |

† **DroneCAN ペリフェラル** (GPS + コンパスノード)。フライトコントローラーではありません。CUAV C-RTK2-HP ベース、ボード ID `6201`。

## リポジトリ構成

```
├── firmware/
│   ├── ardupilot/              # ArduPilot ソース (git submodule)
│   └── betaflight/             # Betaflight ソース (git submodule)
├── boards/
│   ├── AF-F4_nano/             # フライトコントローラー
│   │   ├── ardupilot/          # hwdef.dat, hwdef-bl.dat, defaults.parm
│   │   ├── betaflight/         # config.h
│   │   └── docs/               # 回路図
│   ├── AF-H7_nano/             # フライトコントローラー
│   │   ├── ardupilot/          # hwdef.dat, hwdef-bl.dat, defaults.parm
│   │   ├── betaflight/         # config.h
│   │   └── docs/               # 回路図
│   └── AP-RTK_dual/            # DroneCAN AP_Periph ペリフェラル (GPS + コンパス)
│       ├── ardupilot/          # hwdef.dat, hwdef-bl.dat
│       └── metadata.yaml
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

フライトコントローラー (機体ファームウェア):

```bash
./scripts/build_ap.sh AF-F4_nano copter
./scripts/build_ap.sh AF-H7_nano copter
```

DroneCAN ペリフェラル (AP_Periph ファームウェア — ターゲットに `AP_Periph` を指定):

```bash
./scripts/build_ap.sh AP-RTK_dual AP_Periph
```

ブートローダーは初回実行時に存在しなければ自動でビルドされます。ArduPilot のビルドには標準の ArduPilot Python パッケージ(`pymavlink`, `empy==3.3.4`, `intelhex` など)が必要で、結合 `*_with_bl.hex` の生成には **`intelhex`** モジュールが必須です。

### Betaflight ビルド

```bash
# ARM ツールチェーンのインストール (初回のみ、GCC 13.3.1 が必要)
cd firmware/betaflight && make arm_sdk_install && cd ../..

# ビルド
./scripts/build_bf.sh AF-F4_nano
./scripts/build_bf.sh AF-H7_nano
```

### 出力

ファームウェア成果物は `releases/<board>/` に収集されます:

```bash
ls releases/AF-F4_nano/ardupilot/
# arducopter.apj  arducopter_with_bl.hex  AF-F4_nano_bl.bin  ...

ls releases/AP-RTK_dual/ardupilot/
# AP_Periph.bin  AP_Periph.apj  AP_Periph_with_bl.hex  AP-RTK_dual_bl.bin  ...
```

## リリース公開

```bash
# 全ボードのファームウェア zip を含む GitHub Release を作成
./scripts/release.sh v1.0.0
```

## 書き込み

フライトコントローラー:

| 方法 | ファイル | タイミング |
|------|----------|------------|
| STLink / DFU | `*_with_bl.hex` | 初回書き込み (ブートローダー含む) |
| Mission Planner | `.apj` | ArduPilot OTA 更新 |
| BF Configurator | `.hex` | Betaflight 更新 |

DroneCAN ペリフェラル (例: AP-RTK dual — USB DFU なし):

| 方法 | ファイル | タイミング |
|------|----------|------------|
| STLink / SWD | `AP_Periph_with_bl.hex` | 初回書き込み (ブートローダー + アプリ、`0x08000000`) |
| Mission Planner → DroneCAN | `AP_Periph.bin` | CAN 経由のファームウェア更新 |

## 仕組み

ボード定義はファームウェアソースから分離されて `boards/` に置かれます。`sync_ap_board.sh` スクリプトが ArduPilot ソースツリーへの相対シンボリックリンクを作成し、ビルドシステムが認識できるようにします。

ファームウェアソースの更新はボード設定とは独立です:

```bash
cd firmware/ardupilot && git pull
```

## ライセンス

ハードウェア設計ファイルは novaX-ALUX 専有です。
ファームウェア定義は各アップストリームのライセンス (GPLv3) に従います。
