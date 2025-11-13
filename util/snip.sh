#!/bin/bash

FILEKEY="snip_$(date +'%Y%m%d%H%M%S')"
FILENAME="$FILEKEY.png"

take_snip() {
	mkdir -p "$SCREENSHOT_DIR"

	FULL_PATH="$SCREENSHOT_DIR/$FILENAME"

	if grim -g "$(slurp)" "$FULL_PATH"; then
		wl-copy "$FULL_PATH"
		wl-copy "$FILEKEY"

		notify-send -t 5000 "Screenshot Captured" "Saved as $FILENAME and copied to clipboard."
	else
		notify-send -t 5000 "Screenshot Cancelled"
	fi
}

if [ -n "$DIRENV_SCREENSHOT_DIR" ]; then
	IMAGE_LOADER="/home/aidanfleming/.typst/local/snips/0.1.0"
	SNIP_MAP="$IMAGE_LOADER/snipmap.csv"
	SCREENSHOT_DIR="$IMAGE_LOADER/screenshots"
	rm "$SNIP_MAP"
	take_snip
    for f in $SCREENSHOT_DIR/*; do
		f="$(basename "${f%}")"
		echo "${f%.*}, $f" >> $SNIP_MAP
	done

else
SCREENSHOT_DIR="$HOME/pictures/screenshots"
take_snip 
fi

