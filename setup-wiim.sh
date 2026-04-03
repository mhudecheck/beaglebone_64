#!/usr/bin/env bash
set -euo pipefail

G=/sys/kernel/config/usb_gadget/wiim_uac2
F="$G/functions/uac2.usb0"
CFG="$G/configs/c.1"
STR="$G/strings/0x409"
CFGSTR="$CFG/strings/0x409"
UDC="$(ls /sys/class/udc | head -n1)"

if [[ -z "${UDC:-}" ]]; then
  echo "No UDC found under /sys/class/udc"
  exit 1
fi

echo "[1/7] stop default gadget service"
sudo systemctl disable --now bb-usb-gadgets.service 2>/dev/null || true

echo "[2/7] unbind any existing gadgets"
for g in /sys/kernel/config/usb_gadget/*; do
  [[ -e "$g/UDC" ]] && echo "" | sudo tee "$g/UDC" >/dev/null || true
done

echo "[3/7] remove old wiim_uac2 gadget if present"
if [[ -d "$G" ]]; then
  sudo rm -f "$CFG/uac2.usb0" 2>/dev/null || true
  sudo rmdir "$G/functions/uac2.usb0" 2>/dev/null || true
  sudo rmdir "$CFGSTR" 2>/dev/null || true
  sudo rmdir "$CFG" 2>/dev/null || true
  sudo rmdir "$STR" 2>/dev/null || true
  sudo rmdir "$G" 2>/dev/null || true
fi

echo "[4/7] load gadget modules"
sudo modprobe libcomposite
sudo modprobe usb_f_uac2

echo "[5/7] create fresh gadget"
sudo mkdir -p "$STR"
sudo mkdir -p "$CFGSTR"
sudo mkdir -p "$F"

echo 0x1d6b     | sudo tee "$G/idVendor" >/dev/null
echo 0x0104     | sudo tee "$G/idProduct" >/dev/null
echo high-speed | sudo tee "$G/max_speed" >/dev/null

echo deadbeef1234 | sudo tee "$STR/serialnumber" >/dev/null
echo BeagleBone   | sudo tee "$STR/manufacturer" >/dev/null
echo WiiM-UAC2    | sudo tee "$STR/product" >/dev/null
echo UAC2         | sudo tee "$CFGSTR/configuration" >/dev/null

echo "[6/7] configure capture side for async UAC2"

# Host-selectable capture rates (comma-separated list)
echo "44100,48000,88200,96000" | sudo tee "$F/c_srate" >/dev/null

# 4-byte samples => S32_LE framing / 32-bit container
echo 4   | sudo tee "$F/c_ssize" >/dev/null

# Stereo
echo 0x3 | sudo tee "$F/c_chmask" >/dev/null

# Async capture with feedback
echo adaptive | sudo tee "$F/c_sync" >/dev/null
echo 1     | sudo tee "$F/c_hs_bint" >/dev/null
#echo 2     | sudo tee "$F/fb_max" >/dev/null

# USB request queue depth
echo 32 | sudo tee "$F/req_number" >/dev/null

sudo ln -s "$F" "$CFG/uac2.usb0"

echo "[7/7] bind gadget"
echo "$UDC" | sudo tee "$G/UDC" >/dev/null

echo
echo "UDC:            $UDC"
echo "function:       $(cat "/sys/class/udc/$UDC/function" 2>/dev/null || echo '?')"
echo "state:          $(cat "/sys/class/udc/$UDC/state" 2>/dev/null || echo '?')"
echo "current_speed:  $(cat "/sys/class/udc/$UDC/current_speed" 2>/dev/null || echo '?')"
echo "c_srate:        $(cat "$F/c_srate")"
echo "c_ssize:        $(cat "$F/c_ssize")"
echo "c_chmask:       $(cat "$F/c_chmask")"
echo "c_sync:         $(cat "$F/c_sync")"
echo "c_hs_bint:      $(cat "$F/c_hs_bint")"
echo "fb_max:         $(cat "$F/fb_max")"
echo "req_number:     $(cat "$F/req_number")"

echo
echo "Try the gadget with:"
echo "  arecord -D hw:UAC2Gadget,0 -f S32_LE -c 2 -r 96000 /dev/null"
echo
echo "Verify the exact exposed ALSA hw params with:"
echo "  arecord -D hw:UAC2Gadget,0 --dump-hw-params -f S32_LE -c 2 -r 96000 /dev/null"
