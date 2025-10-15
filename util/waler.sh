#!/bin/bash


if [ "$#" -eq 0 ] || [ "$#" -gt 3 ]; then
    echo "Usage: $0 <path_to_image> [scheme_type] [saturation: -1.0 - 1.0]"
    exit 1
fi

INPUT_PATH="$1"
FULL_PATH=""

if [[ "$INPUT_PATH" == /* ]]; then
    FULL_PATH="$INPUT_PATH"
else
    FULL_PATH="$HOME/pictures/$INPUT_PATH"
fi

if [ ! -f "$FULL_PATH" ]; then
    echo "Error: Image file not found at '$FULL_PATH'"
    exit 1
fi

FILENAME_WITH_EXT=$(basename "$FULL_PATH")
FILENAME_NO_EXT="${FILENAME_WITH_EXT%.*}"

echo "Generating theme from: $FULL_PATH"


if [ -n "$3" ]; then
	echo "Running wal..."
	wal -i "$FULL_PATH" --cols16 -p "$FILENAME_NO_EXT" --saturate "$3"
else
	wal -i "$FULL_PATH" --cols16 -p "$FILENAME_NO_EXT"
fi

if [ -n "$2" ]; then
    echo "Applying matugen scheme type: $2"
    matugen image "$FULL_PATH" -c "$HOME/.cache/wal/matugen.toml" --type scheme-"$2"
else
    matugen image "$FULL_PATH" -c "$HOME/.cache/wal/matugen.toml"
fi
