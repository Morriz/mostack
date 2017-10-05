#!/usr/bin/env bash
root=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )

# install helm charts
cd $root/charts
helm init
helmfile charts
cd $root

sleep 10

# wait until pod ready
cmd="kubectl -n kube-system get po -l app=kube-lego"
pod="$( $cmd )"
echo "waiting for kube-lego"
if [ -z $pod ]; then
  until [ ! -z $pod ]; do
    pod=$( $cmd )
    sleep 3
  done
fi

sleep 10

# port forward to lego for now, until we fix throughput
kubectl -n kube-system port-forward $(kubectl -n kube-system get po -l app=kube-lego -o jsonpath='{.items[0].metadata.name}') 8080:8080 &
# and run tunnel
$root/bin/tunnel-to-minikube-ingress.sh

# install local k8s files
bin/apply.sh

