#!/usr/bin/env bash
root=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )
. $root/bin/colors.sh
shopt -s expand_aliases
. $root/bin/aliases

k config use-context minikube

mkk

#packages=$(helm --tiller-namespace=tiller ls | awk '{print $1}')
#for i in "${packages[@]:5}"; do hk ${i}; done

helm reset --force --tiller-namespace=tiller
rm -rf $USER/.helm

k delete -f $root/k8s/pvc-minikube.yaml
k delete -f $root/k8s/cluster.yaml



