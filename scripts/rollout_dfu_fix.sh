#!/usr/bin/env bash
# Roll out the software-DFU bootloader fix to all FC boards.
# Forces a clean bootloader + app rebuild per board so the patched board.c/Util.cpp and the
# regenerated (DFU-enabled) bootloader are actually compiled in. Bumps versions:
#   4 boards -> 0.2.2 (global VERSION), T10 -> 0.3.2 (board-scoped).
set -uo pipefail
ROOT=/home/sk24/flight_controller
export PATH="$HOME/arm-gcc/gcc-arm-none-eabi-10-2020-q4-major/bin:$PATH"
cd "$ROOT"

echo "0.2.3" > VERSION
echo "VERSION -> $(cat VERSION)"

declare -A VER=( [AF-F4_nano]=0.2.3 [AF-F7_mini]=0.2.3 [AF-H7_nano]=0.2.3 [AF-H7E]=0.2.3 [AF-F4_T10_nano]=0.3.3 )
BOARDS=(AF-F4_nano AF-F7_mini AF-H7_nano AF-H7E AF-F4_T10_nano)
FAIL=()
for b in "${BOARDS[@]}"; do
  echo "==================== $b  (v${VER[$b]}) ===================="
  scripts/sync_ap_board.sh "$b" || { FAIL+=("$b:sync"); continue; }
  rm -rf firmware/ardupilot/build/"$b"
  ( cd firmware/ardupilot && python3 Tools/scripts/build_bootloaders.py "$b" ) || { FAIL+=("$b:bl"); continue; }
  NOVAX_VERSION="${VER[$b]}" scripts/build_ap.sh "$b" copter || { FAIL+=("$b:app"); continue; }
  echo "---- $b done ----"
done
echo "==================== SUMMARY ===================="
[ ${#FAIL[@]} -eq 0 ] && echo "ALL 5 BOARDS OK" || echo "FAILURES: ${FAIL[*]}"
