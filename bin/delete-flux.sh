#!/usr/bin/env bash
shopt -s expand_aliases
. bin/aliases

hk flux
k delete crd fluxhelmreleases.helm.integrations.flux.weave.works helmreleases.flux.weave.works
