#!/usr/bin/env bash

initital_tag=$(dwlmsg -g -t | grep 'tag' | awk '/1$/ {print $3; exit}')
new_tag=$(("$1" - 1))

if [[ $initital_tag != "" ]]; then
	dwlmsg -s -t $new_tag
else
	dwlmsg -s -t $new_tag
	initial_wall=$(swww query | awk '{print $(NF-0)}')
	wall_one="/home/aidanfleming/pictures/wallpapers/one.png"
	wall_two="/home/aidanfleming/pictures/wallpapers/two.png"
		if [ "$initial_wall" = "$wall_one" ]; then
    		OTHER_WALL="$wall_two"
			else
			OTHER_WALL="$wall_one"
		fi
	swww img "$OTHER_WALL" --transition-type none
fi
