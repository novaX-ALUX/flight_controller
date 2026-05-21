#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BOARD_NAME="${1:-AF-F4_nano}"
VEHICLE="${2:-copter}"

AP_ROOT="${ROOT_DIR}/firmware/ardupilot"
BUILD_LINK="${ROOT_DIR}/build/ardupilot"
LOCK_FILE="${AP_ROOT}/.lock-waf_linux_build"

"${ROOT_DIR}/scripts/sync_ap_board.sh" "${BOARD_NAME}"

if [[ -f "${LOCK_FILE}" ]]; then
    rm -f "${LOCK_FILE}"
fi

BUILD_LINK_DIR="$(dirname "${BUILD_LINK}")"
BUILD_REL="$(realpath --relative-to="${BUILD_LINK_DIR}" "${AP_ROOT}/build")"
if [[ -L "${BUILD_LINK}" ]]; then
    if [[ "$(readlink "${BUILD_LINK}")" != "${BUILD_REL}" ]]; then
        rm "${BUILD_LINK}"
        ln -s "${BUILD_REL}" "${BUILD_LINK}"
    fi
elif [[ ! -e "${BUILD_LINK}" ]]; then
    mkdir -p "${BUILD_LINK_DIR}"
    ln -s "${BUILD_REL}" "${BUILD_LINK}"
fi

cd "${AP_ROOT}"

# Build bootloader first if it doesn't exist (required for boards with custom Board ID)
BL_BIN="${AP_ROOT}/Tools/bootloaders/${BOARD_NAME}_bl.bin"
if [[ ! -f "${BL_BIN}" ]]; then
    echo "Bootloader not found, building: ${BL_BIN}"
    python3 Tools/scripts/build_bootloaders.py "${BOARD_NAME}"
fi

./waf configure --board "${BOARD_NAME}"
./waf "${VEHICLE}"

"${ROOT_DIR}/scripts/package_fw.sh" "${BOARD_NAME}" "${VEHICLE}"

echo "Build outputs:"
echo "  build link: ${BUILD_LINK}/${BOARD_NAME}"
echo "  release dir: ${ROOT_DIR}/releases/${BOARD_NAME}/ardupilot"
