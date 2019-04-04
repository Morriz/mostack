#!/usr/bin/env bash
shopt -s expand_aliases
. bin/aliases

hk istio
k delete validatingwebhookconfiguration istio-galley
