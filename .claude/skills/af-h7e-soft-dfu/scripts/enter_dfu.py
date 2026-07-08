#!/usr/bin/env python3
"""
AF-H7E (novaX, STM32H753) enter software DFU.

Send MAV_CMD_PREFLIGHT_REBOOT_SHUTDOWN(246) over USB MAVLink together with the magic sequence.
The param4 debug handlers all sit behind the param1=42, param2=24, param3=71 guard, so without
those values boot_to_dfu() is never even called.

On success the board resets, re-enumerates as 0483:df11 and the app COM disappears. The moment it
resets, pymavlink throws a SerialException (the COM port went away) — that is the expected success
signal, not an error.

Usage: python enter_dfu.py [COM_PORT]   (defaults to COM63)
From WSL, run the Windows Python via powershell.exe interop (the board's USB is on Windows):
  powershell.exe -NoProfile -Command "& 'C:\\path\\to\\python.exe' enter_dfu.py COM63"
Confirm entry (Windows):
  Get-CimInstance Win32_PnPEntity -Filter "DeviceID LIKE '%VID_0483&PID_DF11%'"
"""
from pymavlink import mavutil
import time, sys

MAV_CMD_PREFLIGHT_REBOOT_SHUTDOWN = 246

port = sys.argv[1] if len(sys.argv) > 1 else 'COM63'
m = mavutil.mavlink_connection(port, baud=115200)
if not m.wait_heartbeat(timeout=10):
    print("NO HEARTBEAT on", port)
    raise SystemExit(1)

print("hb sys=%d -> REBOOT_SHUTDOWN magic(42,24,71) param4=99 (enter soft DFU)" % m.target_system)
# param1=42, param2=24, param3=71 (magic gate), param4=99 (boot_to_dfu)
m.mav.command_long_send(
    m.target_system, m.target_component,
    MAV_CMD_PREFLIGHT_REBOOT_SHUTDOWN, 0,
    42.0, 24.0, 71.0, 99.0, 0, 0, 0)

# Grab a STATUSTEXT/ACK for a moment before the reset drops the COM port (optional).
t = time.time()
try:
    while time.time() - t < 3:
        msg = m.recv_match(type=['STATUSTEXT', 'COMMAND_ACK'], blocking=True, timeout=1)
        if msg is None:
            continue
        if msg.get_type() == 'STATUSTEXT':
            txt = msg.text if isinstance(msg.text, str) else bytes(msg.text).decode('utf-8', 'ignore')
            print("STATUSTEXT:", txt)
        else:
            print("ACK cmd=%d result=%d" % (msg.command, msg.result))
except Exception as e:
    # The port vanishing on reset lands here = DFU entry success signal.
    print("port dropped (reset -> DFU expected):", type(e).__name__)
finally:
    try:
        m.close()
    except Exception:
        pass
print("SENT")
