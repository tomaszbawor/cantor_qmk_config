#!/usr/bin/env bash
set -euo pipefail

# --- Config ---
FIRMWARE_FILE="./result/cantor_tbawor_theme.bin"
FLASH_TOOL="dfu-util"
EXTRA_FLAGS="-a 0 -s 0x08000000:leave"

# --- Verify firmware exists ---
if [[ ! -f "$FIRMWARE_FILE" ]]; then
  echo "❌ Firmware file not found: $FIRMWARE_FILE"
  echo "Did you run: nix build ?"
  exit 1
fi

echo "✅ Found firmware: $FIRMWARE_FILE"
echo "⚠️  Please reset your keyboard into bootloader mode (press reset or boot key)..."
sleep 5

# --- Flash it ---
echo "🚀 Flashing firmware using $FLASH_TOOL..."

if "$FLASH_TOOL" -D "$FIRMWARE_FILE" $EXTRA_FLAGS; then
  echo "✅ Flash successful!"
else
  echo "⚠️ Flashing failed — trying with sudo..."
  if sudo "$FLASH_TOOL" -D "$FIRMWARE_FILE" $EXTRA_FLAGS; then
    echo "✅ Flash successful with sudo!"
  else
    echo "❌ Flash failed even with sudo. Check USB permissions or udev rules."
    exit 1
  fi
fi
