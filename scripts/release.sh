#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TAG="${1:?Usage: release.sh <version>  e.g. release.sh v1.0.0}"
shift
BOARDS=("${@}")

if [[ ${#BOARDS[@]} -eq 0 ]]; then
    mapfile -t BOARDS < <(find "${ROOT_DIR}/releases" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort)
fi

if [[ ${#BOARDS[@]} -eq 0 ]]; then
    echo "No release artifacts found in releases/. Build first." >&2
    exit 1
fi

ASSETS=()
NOTES="## Firmware Release ${TAG}"$'\n\n'
NOTES+="| Board | Platform | Commit |"$'\n'
NOTES+="|-------|----------|--------|"$'\n'

for BOARD in "${BOARDS[@]}"; do
    BOARD_RELEASE="${ROOT_DIR}/releases/${BOARD}"
    if [[ ! -d "${BOARD_RELEASE}" ]]; then
        echo "Warning: no releases for ${BOARD}, skipping" >&2
        continue
    fi

    # Zip named: <board>_<tag>.zip
    ZIP="${ROOT_DIR}/releases/${BOARD}_${TAG}.zip"
    (cd "${BOARD_RELEASE}" && zip -r "${ZIP}" .)
    ASSETS+=("${ZIP}")

    # Collect info per platform
    for PLATFORM_DIR in "${BOARD_RELEASE}"/*/; do
        [[ -d "${PLATFORM_DIR}" ]] || continue
        PLATFORM="$(basename "${PLATFORM_DIR}")"
        MANIFEST="${PLATFORM_DIR}/manifest.txt"
        COMMIT="-"
        if [[ -f "${MANIFEST}" ]]; then
            COMMIT="$(grep '^ap_commit=' "${MANIFEST}" 2>/dev/null | cut -d= -f2 || echo "-")"
        fi
        NOTES+="| ${BOARD} | ${PLATFORM} | \`${COMMIT}\` |"$'\n'
    done
done

if [[ ${#ASSETS[@]} -eq 0 ]]; then
    echo "No assets to upload." >&2
    exit 1
fi

NOTES+=$'\n'
NOTES+="### Download"$'\n\n'
NOTES+="Each zip is named \`<board>_${TAG}.zip\` and contains per-platform subdirectories:"$'\n'
NOTES+='```'$'\n'
NOTES+="<board>_${TAG}.zip"$'\n'
NOTES+="├── ardupilot/"$'\n'
NOTES+="│   ├── arducopter.apj        # OTA update via Mission Planner"$'\n'
NOTES+="│   ├── arducopter_with_bl.hex # First flash via STLink/DFU"$'\n'
NOTES+="│   └── <board>_bl.*          # Bootloader"$'\n'
NOTES+="└── betaflight/"$'\n'
NOTES+="    └── betaflight_<board>.hex # Flash via BF Configurator"$'\n'
NOTES+='```'$'\n'

echo "Creating GitHub Release: ${TAG}"
echo ""
for A in "${ASSETS[@]}"; do
    echo "  $(basename "${A}")"
done

gh release create "${TAG}" \
    --title "${TAG}" \
    --notes "${NOTES}" \
    "${ASSETS[@]}"

for A in "${ASSETS[@]}"; do
    rm -f "${A}"
done

echo ""
echo "Published: https://github.com/novaX-ALUX/flight_controller/releases/tag/${TAG}"
