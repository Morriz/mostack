#!/usr/bin/env bash
root=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )
. $root/bin/colors.sh

helm init

printf "${COLOR_BLUE}waiting for tiller to become available${COLOR_BROWN}\n"
kubectl rollout status -w deployment/tiller-deploy -n kube-system
printf "${COLOR_NC}"

printf "${COLOR_BLUE}installing remote charts${COLOR_GREEN}\n"
helm upgrade --install prometheus stable/prometheus -f $root/values/prometheus.yaml
helm upgrade --install grafana stable/grafana -f $root/values/grafana.yaml
printf "${COLOR_NC}"
