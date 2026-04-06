#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BOARD_NAME="${1:-novaX_H743_V1}"

BF_ROOT="${ROOT_DIR}/firmware/betaflight"
BOARD_BF_DIR="${ROOT_DIR}/boards/${BOARD_NAME}/betaflight"
BF_CONFIG_DIR="${BF_ROOT}/src/config/configs/${BOARD_NAME}"
RELEASE_DIR="${ROOT_DIR}/releases/${BOARD_NAME}/betaflight"

if [[ ! -d "${BOARD_BF_DIR}" ]]; then
    echo "No Betaflight config for board: ${BOARD_NAME}" >&2
    exit 1
fi

# Sync board config into BF source tree
mkdir -p "${BF_CONFIG_DIR}"
cp -f "${BOARD_BF_DIR}/config.h" "${BF_CONFIG_DIR}/config.h"
echo "Synced ${BOARD_NAME} Betaflight config"

# Install ARM SDK if not present
ARM_SDK_BIN="${BF_ROOT}/tools/arm-gnu-toolchain-13.3.rel1-x86_64-arm-none-eabi/bin/arm-none-eabi-gcc"
if [[ ! -f "${ARM_SDK_BIN}" ]]; then
    echo "ARM SDK not found, run: make arm_sdk_install (in firmware/betaflight/)"
    echo "Or download manually and extract to: ${BF_ROOT}/tools/"
    exit 1
fi

cd "${BF_ROOT}"
make CONFIG="${BOARD_NAME}"

# Package
mkdir -p "${RELEASE_DIR}"
BF_HEX="${BF_ROOT}/obj/main/betaflight_${BOARD_NAME}.hex"
BF_BIN="${BF_ROOT}/obj/main/betaflight_${BOARD_NAME}.bin"

if [[ -f "${BF_HEX}" ]]; then
    cp -f "${BF_HEX}" "${RELEASE_DIR}/"
fi
if [[ -f "${BF_BIN}" ]]; then
    cp -f "${BF_BIN}" "${RELEASE_DIR}/"
fi

echo "Betaflight build outputs in ${RELEASE_DIR}"
