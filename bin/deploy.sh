#!/usr/bin/env bash
root=$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd .. && pwd)
. bin/colors.sh
shopt -s expand_aliases
. bin/aliases

hs flux \
--set image.tag=1.8.0 \
--set rbac.create=true \
--set helmOperator.create=true \
--set git.url=ssh://git@github.com/morriz/mostack \
--set git.branch=gitops \
--set git.path=namespaces \
--set git.path=releases \
--set git.ciSkip=true \
charts/flux

#--set git.path=namespaces \
