#!/usr/bin/env bash
set -euo pipefail

# --- Configuration ---
FIRMWARE_PATH="./result"
FLASH_TOOL="qmk" # Change to "dfu-util" or "hid_bootloader_cli" if needed
EXTRA_FLAGS=""   # Add board-specific flags here if needed

# --- Find firmware file ---
FIRMWARE_FILE=$(find "$FIRMWARE_PATH" -type f \( -name '*.bin' -o -name '*.hex' \) -print -quit)

if [[ -z "$FIRMWARE_FILE" ]]; then
  echo "❌ No firmware (.hex or .bin) found in: $FIRMWARE_PATH"
  exit 1
fi

echo "✅ Firmware found: $FIRMWARE_FILE"
echo "⚠️ Please reset your keyboard into bootloader mode (press reset or unplug+plug with key held)..."
sleep 5

# --- Flash ---
echo "🚀 Flashing firmware using $FLASH_TOOL..."

case "$FLASH_TOOL" in
qmk)
  qmk flash -f "$FIRMWARE_FILE" $EXTRA_FLAGS
  ;;
dfu-util)
  dfu-util -D "$FIRMWARE_FILE" $EXTRA_FLAGS
  ;;
hid_bootloader_cli)
  hid_bootloader_cli --mcu=atmega32u4 -w "$FIRMWARE_FILE" -v
  ;;
*)
  echo "❌ Unknown flash tool: $FLASH_TOOL"
  exit 1
  ;;
esac

echo "✅ Flash complete!"
