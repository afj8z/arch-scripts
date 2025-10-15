#!/bin/bash

SCREENSHOT_DIR="$HOME/pictures/screenshots"

mkdir -p "$SCREENSHOT_DIR"

FILENAME="screenshot_$(date +'%Y-%m-%d_%H%M%S').png"
FULL_PATH="$SCREENSHOT_DIR/$FILENAME"

if grim -g "$(slurp)" "$FULL_PATH"; then
    wl-copy "$FULL_PATH"
    
    notify-send -t 5000 "Screenshot Captured" "Saved as $FILENAME and copied to clipboard."
else
    notify-send -t 5000 "Screenshot Cancelled"
fi
