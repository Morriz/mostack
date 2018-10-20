#!/usr/bin/env bash
shopt -s expand_aliases
. $root/bin/aliases

`h list | awk '{print $1}' | tail -n +2 | xargs helm --tiller-namespace=tiller delete`


