#!/bin/bash

QUOTES_FILE="$HOME/documents/quotes.txt"

if [[ ! -f "$QUOTES_FILE" ]]; then
    >&2 echo "Error: Quotes file not found at '$QUOTES_FILE'"
    exit 1
fi

shuf -n 1 "$QUOTES_FILE"
