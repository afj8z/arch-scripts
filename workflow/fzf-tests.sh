#!/usr/bin/env bash

TEST_DIR="$HOME/test"
SESS="test"
EDITOR="${EDITOR:-nvim}" 

mkdir -p "$TEST_DIR"

LANGS=$(echo -e "python\nshellscript\ntypst\nlua\nc" | \
    fzf --prompt="Select Language > " --margin 5% --color="bw" --exit-0)

[ -z "$LANGS" ] && exit 0

case "$LANGS" in
    python)      EXT="py" ;;
    shellscript) EXT="sh" ;;
    typst)       EXT="typ" ;;
    lua)         EXT="lua" ;;
    c)           EXT="c" ;;
    *)           echo "Unknown language"; exit 1 ;;
esac

ACTION=$(echo -e "New File\nExisting File" | \
    fzf --prompt="Action ($LANGS) > " --margin 5% --color="bw" --reverse --exit-0)

[ -z "$ACTION" ] && exit 0

TARGET_FILE=""

if [ "$ACTION" == "New File" ]; then
    n=1
    while [[ -e "$TEST_DIR/test${n}.${EXT}" ]]; do
        ((n++))
    done
    TARGET_FILE="$TEST_DIR/test${n}.${EXT}"
    
    touch "$TARGET_FILE"
    
    # Add shebang for shell scripts
    if [ "$EXT" == "sh" ]; then
        chmod +x "$TARGET_FILE"
        echo "#!/usr/bin/env bash" > "$TARGET_FILE"
    fi

elif [ "$ACTION" == "Existing File" ]; then
    SELECTED_FILENAME=$(find "$TEST_DIR" -maxdepth 1 -name "*.${EXT}" -printf "%f\n" | \
        fzf --prompt="Open File > " --margin 5% --color="bw" --reverse --exit-0)
    
    [ -z "$SELECTED_FILENAME" ] && exit 0
    TARGET_FILE="$TEST_DIR/$SELECTED_FILENAME"
fi

# check if session exists -> create session
if ! tmux has-session -t "=${SESS}" 2> /dev/null; then
    tmux new-session -ds "$SESS" -c "$TEST_DIR"
    tmux select-window -t "${SESS}:1" 2> /dev/null
fi

# new window in session with editor
tmux new-window -t "${SESS}:" -c "$TEST_DIR" -n "$(basename "$TARGET_FILE")" "$EDITOR '$TARGET_FILE'"

tmux switch-client -t "=${SESS}"
