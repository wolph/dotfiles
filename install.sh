#!/bin/sh

for file in _*; do
    destination="$HOME/$(echo $file | sed 's/^_/./')"
    source=$PWD/$file
    if [ -e "$destination" ]; then
        echo "$destination already exists, not linking."
    else
        ln -sv "$source" "$destination"
    fi
done

