#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BOARD_NAME="${1:-AF-H7_nano}"

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
ARM_SDK_DIR="${BF_ROOT}/tools/arm-gnu-toolchain-13.3.rel1-x86_64-arm-none-eabi"
ARM_SDK_BIN="${ARM_SDK_DIR}/bin/arm-none-eabi-gcc"
if [[ ! -f "${ARM_SDK_BIN}" ]]; then
    ARM_SDK_URL="https://developer.arm.com/-/media/Files/downloads/gnu/13.3.rel1/binrel/arm-gnu-toolchain-13.3.rel1-x86_64-arm-none-eabi.tar.xz"
    ARM_SDK_FILE="${BF_ROOT}/tools/arm-sdk.tar.xz"
    echo "ARM SDK not found, downloading..."
    mkdir -p "${BF_ROOT}/tools"
    curl -L -o "${ARM_SDK_FILE}" "${ARM_SDK_URL}"
    echo "Extracting..."
    tar xf "${ARM_SDK_FILE}" -C "${BF_ROOT}/tools/"
    rm -f "${ARM_SDK_FILE}"
    echo "ARM SDK installed"
fi

cd "${BF_ROOT}"
make CONFIG="${BOARD_NAME}"

# Package - BF output names include version and MCU, use glob to find them
mkdir -p "${RELEASE_DIR}"

for f in "${BF_ROOT}"/obj/betaflight_*_"${BOARD_NAME}".hex "${BF_ROOT}"/obj/betaflight_*_"${BOARD_NAME}".bin; do
    if [[ -f "${f}" ]]; then
        cp -f "${f}" "${RELEASE_DIR}/"
    fi
done

echo "Betaflight build outputs in ${RELEASE_DIR}"
