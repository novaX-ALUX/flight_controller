#!/usr/bin/env python3
"""
AF-H7E (novaX, STM32H753) 소프트웨어 DFU 진입.

USB MAVLink로 MAV_CMD_PREFLIGHT_REBOOT_SHUTDOWN(246)을 매직 시퀀스와 함께 전송한다.
param4 디버그 핸들러는 반드시 param1=42, param2=24, param3=71 가드 안에 있으므로
이 값들이 없으면 boot_to_dfu()가 호출조차 되지 않는다.

성공 시 보드는 리셋되어 0483:df11로 열거되고 앱 COM은 사라진다.
리셋 순간 pymavlink가 SerialException(장치가 명령을 인식하지 않습니다)을 던지는 것은
COM이 사라진 것 = 정상/성공 신호다.

사용: python enter_dfu.py [COM포트]   (기본 COM63)
WSL에서는 윈도우 파이썬을 powershell.exe interop로 실행:
  powershell.exe -NoProfile -Command "& 'C:\\...\\python.exe' enter_dfu.py COM63"
진입 확인(Windows):
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

# 보드가 리셋되며 COM이 사라지기 전 잠깐 STATUSTEXT/ACK를 잡아본다(선택).
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
    # 리셋으로 포트가 사라지면 여기로 온다 = DFU 진입 성공 신호
    print("port dropped (reset -> DFU expected):", type(e).__name__)
finally:
    try:
        m.close()
    except Exception:
        pass
print("SENT")
