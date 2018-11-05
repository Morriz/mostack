#!/usr/bin/env bash
root=$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd .. && pwd)
. bin/colors.sh
shopt -s expand_aliases
. bin/aliases

# helm --tiller-namespace=kube-system --namespace=system install --name flux \ 
hs flux \
--set rbac.create=true \
--set helmOperator.create=true \
--set git.url=ssh://git@github.com:Morriz/mostack \
--set git.branch=gitops \
charts/flux