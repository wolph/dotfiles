#!/bin/sh

delete=false
replace=false

while getopts dr o
do
    case "$o" in
        d) delete=true;;
        r) replace=true;;
        [?]) print >&2 "Usage: $0 [-r] [-d]"
    esac
done

link(){
    source="$1"
    destination="$2"

    if [ -h "$destination" ]; then
        echo "$destination already linked, not linking."
        continue
    elif [ -e "$destination" ]; then
        if [ $replace ]; then
            mv -vi "$destination" "${destination}.bak"
        elif [ $delete ]; then
            rm -vi "$destination"
        fi
    fi

    if [ -e "$destination" ]; then
        echo "$destination already exists, not linking."
    else
        ln -sv "$source" "$destination"
    fi
}

for file in _*; do
    destination="$HOME/$(echo $file | sed 's/^_/./')"
    source=$PWD/$file
    link "$source" "$destination"
done

mkdir -p "$HOME/bin"
for file in bin/*; do
    destination="$HOME/$file"
    source=$PWD/$file
    link "$source" "$destination"
done

