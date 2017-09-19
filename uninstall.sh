#!/bin/sh

unlink(){
    source="$1"
    destination="$2"
    link=$(readlink "$destination")

    if [ "$source" = "$link" ]; then
        echo "Removing $source -> $destination"
        rm -f "$destination"
    else
        echo "Not removing $destination, it is not pointing to $source anymore"
    fi
}

for file in _*; do
    destination="$HOME/$(echo $file | sed 's/^_/./')"
    source=$PWD/$file
    unlink "$source" "$destination"
done

for file in bin/*; do
    destination="$HOME/$file"
    source=$PWD/$file
    unlink "$source" "$destination"
done

for file in envs/*; do
    destination="$HOME/$file"
    source=$PWD/$file
    unlink "$source" "$destination"
done
