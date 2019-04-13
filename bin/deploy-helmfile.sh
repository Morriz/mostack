#!/usr/bin/env bash

# install crds
helmfile --selector phase=init apply

# and the rest
helmfile apply

[ -n "$ISLOCAL" ] && bin/ngrok.sh
