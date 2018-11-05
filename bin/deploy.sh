#!/usr/bin/env bash
root=$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd .. && pwd)
. bin/colors.sh
shopt -s expand_aliases
. bin/aliases

printf "${COLOR_BLUE}Deploying Flux Operator${COLOR_NC}\n"
hs flux \ 
--set rbac.create=true \
--set helmOperator.create=true \
--set git.url=ssh://git@github.com:Morriz/mostack \
--set git.branch=gitops
--namespace system \
charts/flux
