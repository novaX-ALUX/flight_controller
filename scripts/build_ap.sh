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

# --- novaX custom firmware version string (shown in GCS) ---------------------
# Inject AP_CUSTOM_FIRMWARE_STRING through --extra-hwdef so each board carries
# its OWN novaX version without editing its hwdef. Version source order:
#   1. NOVAX_VERSION env var        (explicit one-off override)
#   2. boards/<board>/VERSION       (per-board version — the normal case)
#   3. repo-root VERSION            (fallback default for boards without one)
#   4. "dev"
# Each hardware is versioned INDEPENDENTLY (e.g. AF-H7E 0.2.9 while AF-F7_mini
# 0.2.3): bumping one board never forces a bump on the others. The upstream
# ArduPilot version is preserved separately in fw_string_original, and the git
# hash is auto-appended by AP_FWVersionDefine.h. Peripherals (AP_Periph, e.g.
# AP-RTK_dual) are on their own track and are intentionally NOT stamped here.
EXTRA_HWDEF_ARGS=()
if [[ "${VEHICLE}" != "AP_Periph" ]]; then
    _BOARD_VERSION_FILE="${ROOT_DIR}/boards/${BOARD_NAME}/VERSION"
    NOVAX_VERSION="${NOVAX_VERSION:-$(cat "${_BOARD_VERSION_FILE}" 2>/dev/null \
        || cat "${ROOT_DIR}/VERSION" 2>/dev/null || echo dev)}"
    # Keep the custom string to just the novaX version; ArduPilot auto-appends the
    # git hash -> "novaX v1.0.0 (g1a2b3c4)". The upstream AP version (THISFIRMWARE)
    # is preserved separately in fw_string_original, so it is not repeated here.
    FW_STR="novaX v${NOVAX_VERSION}"
    EXTRA_HWDEF="${ROOT_DIR}/build/novax_version_${BOARD_NAME}.hwdef"
    mkdir -p "${ROOT_DIR}/build"
    printf 'define AP_CUSTOM_FIRMWARE_STRING "%s"\n' "${FW_STR}" > "${EXTRA_HWDEF}"
    EXTRA_HWDEF_ARGS=(--extra-hwdef "${EXTRA_HWDEF}")
    export NOVAX_VERSION
    echo "novaX firmware string: ${FW_STR}"
fi

./waf configure --board "${BOARD_NAME}" ${EXTRA_HWDEF_ARGS[@]+"${EXTRA_HWDEF_ARGS[@]}"}
./waf "${VEHICLE}"

"${ROOT_DIR}/scripts/package_fw.sh" "${BOARD_NAME}" "${VEHICLE}"

echo "Build outputs:"
echo "  build link: ${BUILD_LINK}/${BOARD_NAME}"
echo "  release dir: ${ROOT_DIR}/releases/${BOARD_NAME}/ardupilot"
