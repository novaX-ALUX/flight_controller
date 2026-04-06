#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TAG="${1:?Usage: release.sh <tag> [board...]  e.g. release.sh v1.0.0 novaX_F405 novaX_H743_V1}"
shift
BOARDS=("${@}")

if [[ ${#BOARDS[@]} -eq 0 ]]; then
    # Default: all boards that have releases
    mapfile -t BOARDS < <(find "${ROOT_DIR}/releases" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort)
fi

if [[ ${#BOARDS[@]} -eq 0 ]]; then
    echo "No release artifacts found in releases/. Build first." >&2
    exit 1
fi

ASSETS=()
NOTES=""

for BOARD in "${BOARDS[@]}"; do
    BOARD_RELEASE="${ROOT_DIR}/releases/${BOARD}"
    if [[ ! -d "${BOARD_RELEASE}" ]]; then
        echo "Warning: no releases for ${BOARD}, skipping" >&2
        continue
    fi

    ZIP="${ROOT_DIR}/releases/${BOARD}_${TAG}.zip"
    (cd "${BOARD_RELEASE}" && zip -r "${ZIP}" .)
    ASSETS+=("${ZIP}")

    # Build notes from manifests
    NOTES+="### ${BOARD}"$'\n'
    for MANIFEST in "${BOARD_RELEASE}"/*/manifest.txt; do
        if [[ -f "${MANIFEST}" ]]; then
            PLATFORM="$(basename "$(dirname "${MANIFEST}")")"
            AP_COMMIT="$(grep '^ap_commit=' "${MANIFEST}" 2>/dev/null | cut -d= -f2 || echo "-")"
            NOTES+="- **${PLATFORM}**: commit \`${AP_COMMIT}\`"$'\n'
        fi
    done
    NOTES+=$'\n'
done

if [[ ${#ASSETS[@]} -eq 0 ]]; then
    echo "No assets to upload." >&2
    exit 1
fi

echo "Creating GitHub Release: ${TAG}"
echo ""
echo "${NOTES}"

# Build gh release command
ASSET_ARGS=()
for A in "${ASSETS[@]}"; do
    ASSET_ARGS+=("${A}")
done

gh release create "${TAG}" \
    --title "${TAG}" \
    --notes "$(cat <<EOF
## Firmware Release ${TAG}

${NOTES}
### Files

Each zip contains:
- \`.apj\` — ArduPilot firmware (upload via Mission Planner)
- \`*_with_bl.hex\` — Full image with bootloader (first flash via STLink/DFU)
- \`*_bl.bin/hex\` — Bootloader only
- \`manifest.txt\` — Build metadata
EOF
)" \
    "${ASSET_ARGS[@]}"

# Cleanup zips
for A in "${ASSETS[@]}"; do
    rm -f "${A}"
done

echo ""
echo "Release ${TAG} published: https://github.com/novaX-ALUX/flight_controller/releases/tag/${TAG}"
