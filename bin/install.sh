#!/usr/bin/env bash
root=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )

: "${ADMIN_EMAIL:?ADMIN_EMAIL not found in env!}"

# osx only: install prerequisites if needed
if [ "`uname -s`"=="Darwin" ]; then
  [[ -x `command -v helm` ]] || brew install helm
fi

# install helm
helm init
kubectl rollout status -w deployment/tiller-deploy --namespace=kube-system

# deploy all charts
cd $root/charts
helmfile charts

[ $? -ne 0 ] && echo "Something went wrong with installing one of the charts. Inspect error and retry" && exit

cd -
# wait dependent charts ready, like lego
echo "waiting for charts to become available:"
kubectl rollout status -w deployment/kube-lego-kube-lego --namespace=kube-system

# and run tunnel to minikube node's port 80 and 443
. $root/bin/tunnel-to-minikube-ingress.sh

# install local k8s files
. bin/apply.sh

