#!/usr/bin/env bash

root=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd ../.. && pwd )
myroot=$root/k8s/drone

echo "  - creating independent files first"
printf "${COLOR_GREEN}"
kubectl apply -f $myroot/drone-rbac.yaml
sleep 3
find $myroot -type f \( -iname '*.yaml' ! -iname '*-rbac.yaml' ! -iname '*agent-deploy.yaml' \) -exec kubectl apply -f {} \;
printf "${COLOR_NC}"
echo '  - now creating dependent files'

# wait until pod ready
cmd="kubectl -n drone get po -l app=drone-server | grep drone-server | grep 1/1"
pod=$( eval $cmd )
echo $pod

echo "    waiting for server pods"
if [ -z $pod ]; then
  until [ ! -z $pod ]; do
    pod=$( eval $cmd )
    sleep 3
  done
  sleep 20
fi

echo "    ready"

printf "${COLOR_GREEN}"
kubectl apply -f $myroot/drone-agent-deploy.yaml
printf "${COLOR_NC}"
