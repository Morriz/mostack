#!/usr/bin/env bash
root=$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd .. && pwd)
. $root/bin/colors.sh
shopt -s expand_aliases
. $root/bin/aliases

provider=${1:-'gce'}
. $root/secrets/${provider}.sh

printf "${COLOR_WHITE}Starting SYSTEM app proxies${COLOR_NC}\n"

killall kubectl > /dev/null 2>&1
k proxy &

ks rollout status -w deploy/nginx-ingress-controller
printf "${COLOR_BLUE}Forwarding local 32080,32443 to nginx controller${COLOR_NC}\n"
kpk 32080 > /dev/null 2>&1
ks port-forward $(ks get po --selector=app=nginx-ingress,component=controller --output=jsonpath={.items..metadata.name}) 32080:80 32443:443 &
# ks port-forward $(ks get po --selector=app=ambassador --output=jsonpath={.items..metadata.name}) 32080:80 32443:443 &

if [ "$ISLOCAL" ]; then
	printf "${COLOR_BLUE}Starting tunnels to allow cert manager ingress${COLOR_NC}\n"
	sh $root/bin/tunnel-to-ingress.sh
	sh $root/bin/ngrok.sh
fi

printf "${COLOR_PURPLE}[system] Waiting for necessary pods to become available${COLOR_BROWN}\n"
ks rollout status -w deploy/weave-scope-frontend-system-weave-scope
kl rollout status -w deploy/elasticsearch
km rollout status -w statefulset.apps/prometheus-prometheus-operator-prometheus
km rollout status -w statefulset.apps/alertmanager-prometheus-operator-alertmanager
ktb rollout status -w statefulset.apps/prometheus-prometheus-operator-team-b-prometheus
ktb rollout status -w statefulset.apps/alertmanager-prometheus-operator-team-b-alertmanager

printf "${COLOR_BLUE}Starting Weave Scope${COLOR_NC}\n"
kpk 4041 > /dev/null 2>&1
ks port-forward deploy/weave-scope-frontend-system-weave-scope 4041:4040 &

printf "${COLOR_BLUE}Starting nginx status proxy${COLOR_NC}\n"
kpk 18080 > /dev/null 2>&1
ks port-forward deploy/nginx-ingress-controller 18080 &

printf "${COLOR_BLUE}Starting elasticsearch proxy${COLOR_NC}\n"
kpk 9200 > /dev/null 2>&1
kl port-forward deploy/elasticsearch 9200 &

printf "${COLOR_BLUE}Starting prometheus proxy${COLOR_NC}\n"
kpk 9090 > /dev/null 2>&1
km port-forward $(km get po --selector=app=prometheus --output=jsonpath={.items..metadata.name}) 9090 &

printf "${COLOR_BLUE}Starting alertmanager proxy${COLOR_NC}\n"
kpk 9093 > /dev/null 2>&1
km port-forward $(km get po --selector=app=alertmanager --output=jsonpath={.items..metadata.name}) 9093 &

printf "${COLOR_WHITE}Starting TEAM FRONTEND app proxies${COLOR_NC}\n"

printf "${COLOR_BLUE}Starting prometheus proxy${COLOR_NC}\n"
kpk 9190 > /dev/null 2>&1
ktb port-forward $(ktb get po --selector=app=prometheus --output=jsonpath={.items..metadata.name}) 9190:9090 &

printf "${COLOR_BLUE}Starting alertmanager proxy${COLOR_NC}\n"
kpk 9193 > /dev/null 2>&1
ktb port-forward $(ktb get po --selector=app=alertmanager --output=jsonpath={.items..metadata.name}) 9193:9093 &

open $root/docgen/service-index.html