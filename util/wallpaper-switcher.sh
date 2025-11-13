#!/usr/bin/env bash


WALLPAPER_DIR="$HOME/pictures/wallpapers"

if [ -z "$1" ]; then
    echo "Error: No wallpaper key provided."
    echo "Usage: $0 <key>"
    echo "Example: $0 1"
    exit 1
fi

case $1 in
    1)         filename_prefix="one" ;;
    2)         filename_prefix="two" ;;
    3)         filename_prefix="three" ;;
    4)         filename_prefix="four" ;;
    5)         filename_prefix="five" ;;
    6)         filename_prefix="six" ;;
    7)         filename_prefix="seven" ;;
    "music")   filename_prefix="music" ;;
    "art")     filename_prefix="art" ;;
    *)
      echo "Error: Invalid key '$1'."
      exit 1
      ;;
esac

wallpaper_files=("$WALLPAPER_DIR/$filename_prefix."*)
wallpaper="${wallpaper_files[0]}"

if ! [ -f "$wallpaper" ]; then
    echo "Error: Wallpaper file not found for key '$1' at path prefix ${WALLPAPER_DIR}/${filename_prefix}"
    exit 1
fi

swww img "$wallpaper" --transition-type none
