#!/usr/bin/env bash

if [ -n "$DIRENV_DIR" ]; then
	echo "in direnv dir"
else
	echo "not in direnv dir"
fi

cat "$DIRENV_SCREENSHOT_DIR"
