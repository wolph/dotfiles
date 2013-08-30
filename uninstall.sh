#!/bin/sh

for file in _*; do
    destination="$HOME/$(echo $file | sed 's/^_/./')"
    link=$(readlink "$destination")
    source=$PWD/$file

    if [ "$source" = "$link" ]; then
        echo "Removing $source -> $destination"
        rm -f "$destination"
    else
        echo "Not removing $destination, it is not pointing to $source anymore"
    fi
done

