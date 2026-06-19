#!/usr/bin/env bash
# Apply novaX patches to the upstream ArduPilot submodule.
# The ardupilot submodule is pinned to upstream (ArduPilot/ardupilot), so core-source fixes
# that are NOT expressible as hwdef overlays live here as patches and must be re-applied after
# a fresh checkout or `git submodule update`. Idempotent: skips patches already applied.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AP="${ROOT}/firmware/ardupilot"
PDIR="${ROOT}/patches/ardupilot"

[ -d "$AP" ] || { echo "ardupilot submodule not found at $AP"; exit 1; }
shopt -s nullglob
for p in "$PDIR"/*.patch; do
  name="$(basename "$p")"
  if git -C "$AP" apply --reverse --check "$p" >/dev/null 2>&1; then
    echo "skip (already applied): $name"
  elif git -C "$AP" apply --check "$p" >/dev/null 2>&1; then
    git -C "$AP" apply "$p" && echo "applied: $name"
  else
    echo "WARN: cannot apply $name (conflict or context drift) — review manually"
  fi
done
