#!/bin/bash

verify_tmux_version () {
    tmux_home=~/.tmux
    tmux_version="$(tmux -V | awk '{print $2}')"
    tmux_major="${tmux_version%%.*}"
    tmux_minor="${tmux_version#*.}"
    tmux_minor="${tmux_minor%%[!0-9]*}"

    if (( tmux_major > 2 || (tmux_major == 2 && tmux_minor >= 1) )) ; then
        tmux source-file "$tmux_home/tmux_2.1_up.conf"
    elif (( tmux_major > 1 || (tmux_major == 1 && tmux_minor >= 9) )) ; then
        tmux source-file "$tmux_home/tmux_1.9_to_2.1.conf"
    else
        tmux source-file "$tmux_home/tmux_1.9_down.conf"
    fi
}

verify_tmux_version
