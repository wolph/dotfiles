#!/usr/bin/env zsh -ve

# Why "materialized" commands instead of simple aliases you ask? Because xargs
# doesn't understand aliases ;)

declare -A kube_aliases

kube_aliases[k]=kubectl
kube_aliases[ka]='kubectl apply'
kube_aliases[kaf]='kubectl apply -f'
kube_aliases[kg]='kubectl get'
kube_aliases[kgp]='kubectl get pod'
kube_aliases[kgj]='kubectl get job'
kube_aliases[kdesc]='kubectl describe'
kube_aliases[kd]='kubectl delete'
kube_aliases[kdf]='kubectl delete -f '
kube_aliases[kc]='kubectl create'
kube_aliases[kcf]='kubectl create -f '

mkdir -p kubernetes-aliases

for alias cmd in ${(kv)kube_aliases}; do
    file=kubernetes-aliases/$alias
    echo '#!/usr/bin/env zsh' > $file
    echo "exec $cmd" > $file
    chmod +x $file
done
