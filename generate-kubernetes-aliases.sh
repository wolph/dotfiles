#!/usr/bin/env zsh -e

# Why "materialized" commands instead of simple aliases you ask? Because xargs
# doesn't understand aliases ;)

declare -A kube_aliases
declare -A operations
declare -A objects

operations[g]=get
operations[e]=edit
operations[a]=apply
operations[c]=create
operations[d]=delete

objects[p]=pod
objects[j]=job
objects[f]='-f '

for op operation in ${(kv)operations}; do
    echo "$op=$operation"
    for obj object in ${(kv)objects}; do
        echo "\t$obj=$object"
        alias_="k${op}${obj}"
        cmd="kubectl ${operation} ${object}"
        kube_aliases[$alias_]=$cmd
    done

    alias_="k${op}"
    cmd="kubectl ${operation}"
    kube_aliases[$alias_]=$cmd
done

echo

kube_aliases[k]=kubectl
kube_aliases[kdesc]='kubectl describe'

mkdir -p kubernetes-aliases

for alias_ cmd in ${(kv)kube_aliases}; do
    echo "$alias_=$cmd"
    file=kubernetes-aliases/$alias_
    echo '#!/usr/bin/env zsh' > $file
    echo "exec $cmd "'$@' > $file
    chmod +x $file
done
