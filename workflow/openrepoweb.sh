#!/usr/bin/env bash

open_url(){
if [ -z "$BROWSER" ];
	then
		$BROWSER "$1" &
	elif command -v xdg-open &> /dev/null;
		then
			$BROWSER "$1" &
	else
		echo "Browser not found - set a default Browser or the \"\$BROWSER\" variable "
	fi
}	

cd "$(tmux run 'echo #{pane_current_path}')" || exit

if [[ $(git rev-parse --is-inside-work-tree) = "true" ]];
	then
		origin_url=$(git config --get remote.origin.url)
		open_url "$origin_url" 
	else
		2&> /dev/null
		echo "is-not-git"
	fi
