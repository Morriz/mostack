#!/usr/bin/env bash

root=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd ../.. && pwd )
myroot=$root/k8s/drone

echo "  - creating independent files first"
printf "${COLOR_GREEN}"
kubectl apply -f $myroot/drone-rbac.yaml
sleep 3
find $myroot -type f \( -iname '*.yaml' ! -iname '*-rbac.yaml' ! -iname '*agent-deploy.yaml' \) -exec kubectl apply -f {} \;
printf "${COLOR_NC}"

kubectl rollout status -w deployment/drone-server --namespace=drone

echo "    ready"
echo '  - now creating dependent files'

printf "${COLOR_GREEN}"
kubectl apply -f $myroot/drone-agent-deploy.yaml
printf "${COLOR_NC}"
