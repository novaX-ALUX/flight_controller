import usb.core, usb.util, usb.backend.libusb1, libusb_package, time
be = usb.backend.libusb1.get_backend(find_library=libusb_package.find_library)
dev = usb.core.find(idVendor=0x0483, idProduct=0xdf11, backend=be)
if dev is None:
    print("NO DFU DEVICE"); raise SystemExit(2)
# Try to clear DFU error state first (ABORT + CLRSTATUS), then a full USB reset so the
# ROM DFU state machine re-initialises to dfuIDLE (recovers a stuck dfuERROR from a
# previously aborted flash without a physical replug).
try:
    dev.ctrl_transfer(0x21, 6, 0, 0)  # DFU_ABORT
except Exception as e:
    print("abort:", e)
try:
    dev.ctrl_transfer(0x21, 4, 0, 0)  # DFU_CLRSTATUS
except Exception as e:
    print("clrstatus:", e)
try:
    dev.reset(); print("USB reset issued")
except Exception as e:
    print("reset err:", e)
