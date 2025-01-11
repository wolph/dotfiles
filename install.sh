#!/bin/sh

delete=false
replace=false

git submodule init
git submodule update

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

mkdir -p "$HOME/envs"
for file in envs/*; do
    destination="$HOME/$file"
    source=$PWD/$file
    link "$source" "$destination"
done

mkdir -p "$HOME/.config"
mkdir -p "$HOME/.vim/autoload"
ln -sf "$HOME/.mpv" "$HOME/.config/mpv"
ln -sf "$HOME/.vim" "$HOME/.config/nvim"
ln -sf "$HOME/.vimrc" "$HOME/.config/nvim/init.vim"
ln -sf vim.lua "$HOME/.config/nvim/init.lua"

# kubernetes aliases
if type kubectl > /dev/null; then
    ./generate-kubernetes-aliases.sh
    for file in kubernetes-aliases/*; do
        destination="$HOME/bin/$(basename $file)"
        source=$PWD/$file
        link "$source" "$destination"
    done
fi

curl -L https://iterm2.com/shell_integration/zsh \
    -o ~/.iterm2_shell_integration.zsh

if [ ! -d ~/.tmux/plugins/tundle ]; then
    git clone --depth=1 https://github.com/javier-lopez/tundle \
        ~/.tmux/plugins/tundle
fi

if [ "$TMUX" ]; then
    tmux source-file ~/.tmux.conf
    ~/.tmux/plugins/tundle/scripts/install_plugins.sh
    ~/.tmux/plugins/tundle/scripts/update_plugins.sh all
fi
