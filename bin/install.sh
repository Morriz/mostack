#!/usr/bin/env bash
root=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )
# if not running minikube, uncomment:
isMini=1

# osx only: install prerequisites if needed
if [ "`uname -s`"=="Darwin" ]; then
  [[ -x `command -v helm` ]] || brew install helm
fi

# if you already have minikube running, uncomment:
isMini && . $root/bin/minikube-install.sh

# deploy all charts
helm template -r mostack $root | kubectl apply -f -

[ $? -ne 0 ] && echo "Something went wrong with installing one of the charts. Inspect error and retry" && exit

# wait dependent charts ready, like lego
echo "waiting for charts to become available:"
kubectl rollout status -w deployment/kube-lego-kube-lego --namespace=kube-system

echo "starting tunnels"
# and run tunnel to minikube node's port 80 and 443
isMini && . $root/bin/tunnel-to-minikube-ingress.sh

