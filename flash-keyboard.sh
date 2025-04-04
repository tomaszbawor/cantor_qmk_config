#!/usr/bin/env bash

set -euo pipefail

FIRMWARE_DIR="./qmk/.build"
HEX_FILE=$(find "$FIRMWARE_DIR" -name '*.hex' -print -quit)
BIN_FILE=$(find "$FIRMWARE_DIR" -name '*.bin' -print -quit)

if [[ -z "$HEX_FILE" && -z "$BIN_FILE" ]]; then
  echo "❌ No firmware files found in $FIRMWARE_DIR"
  exit 1
fi

FIRMWARE_FILE="${HEX_FILE:-$BIN_FILE}"

echo "✅ Found firmware: $FIRMWARE_FILE"
echo "⚠️ Please reset your keyboard into bootloader mode..."

# Wait for device to show up (for example via dfu-util or avrdude target)
# Adjust this line based on your board (DFU, Caterina, HID, etc.)
sleep 5

echo "🚀 Flashing firmware..."

qmk flash -b -f "$FIRMWARE_FILE"
