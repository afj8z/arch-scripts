#!/bin/env bash

SEARCH_DIRS=(
"$HOME/documents/uni/2025W/"
)

fzf_output=$(find "${SEARCH_DIRS[@]}" -type f -iname "*.pdf" | \
             awk -F/ '{print $(NF-1) "/" $NF "\t" $0}' | \
             fzf --with-nth=1 --delimiter=$'\t' --margin 5% --color="bw")

if [ -n "$fzf_output" ]; then
    selection=$(echo "$fzf_output" | cut -f2 -d$'\t')

    tmux new-window -d zathura "$selection"
	tmux select-window -l
fi
