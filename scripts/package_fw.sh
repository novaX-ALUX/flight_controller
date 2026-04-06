#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BOARD_NAME="${1:-novaX_F405}"
VEHICLE="${2:-copter}"

AP_ROOT="${ROOT_DIR}/firmware/ardupilot"
RELEASE_DIR="${ROOT_DIR}/releases/${BOARD_NAME}/ardupilot"
BOOTLOADER_DIR="${AP_ROOT}/Tools/bootloaders"
BIN_DIR="${AP_ROOT}/build/${BOARD_NAME}/bin"

case "${VEHICLE}" in
    copter)
        VEHICLE_BIN="arducopter"
        ;;
    plane)
        VEHICLE_BIN="arduplane"
        ;;
    rover)
        VEHICLE_BIN="ardurover"
        ;;
    sub)
        VEHICLE_BIN="ardusub"
        ;;
    tracker)
        VEHICLE_BIN="antennatracker"
        ;;
    blimp)
        VEHICLE_BIN="blimp"
        ;;
    *)
        echo "Unsupported vehicle target: ${VEHICLE}" >&2
        exit 1
        ;;
esac

mkdir -p "${RELEASE_DIR}"

copy_if_exists() {
    local src="$1"
    local dst="$2"
    if [[ -f "${src}" ]]; then
        cp -f "${src}" "${dst}"
    fi
}

copy_if_exists "${BOOTLOADER_DIR}/${BOARD_NAME}_bl.bin" "${RELEASE_DIR}/${BOARD_NAME}_bl.bin"
copy_if_exists "${BOOTLOADER_DIR}/${BOARD_NAME}_bl.hex" "${RELEASE_DIR}/${BOARD_NAME}_bl.hex"
copy_if_exists "${BOOTLOADER_DIR}/${BOARD_NAME}_bl.elf" "${RELEASE_DIR}/${BOARD_NAME}_bl.elf"
copy_if_exists "${BIN_DIR}/${VEHICLE_BIN}.apj" "${RELEASE_DIR}/${VEHICLE_BIN}.apj"
copy_if_exists "${BIN_DIR}/${VEHICLE_BIN}_with_bl.hex" "${RELEASE_DIR}/${VEHICLE_BIN}_with_bl.hex"

MANIFEST_PATH="${RELEASE_DIR}/manifest.txt"
{
    echo "board=${BOARD_NAME}"
    echo "vehicle=${VEHICLE}"
    echo "source_tree=firmware/ardupilot"
    echo "board_config=boards/${BOARD_NAME}/ardupilot"
    echo "ap_commit=$(git -C "${AP_ROOT}" rev-parse --short HEAD 2>/dev/null || echo unknown)"
    echo "generated_at=$(date -Iseconds)"
    echo "files:"
    find "${RELEASE_DIR}" -maxdepth 1 -type f ! -name manifest.txt -printf '  %f\n' | sort
} > "${MANIFEST_PATH}"

echo "Packaged firmware in ${RELEASE_DIR}"
