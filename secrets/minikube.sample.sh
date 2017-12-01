#!/usr/bin/env bash

export MINIKUBE_IP='192.168.99.100'
export NGROK_TOKEN=''

export LEGO_EMAIL='you@yourdoma.in'

export CLUSTER_ENV=dev
export CLUSTER_HOST="$CLUSTER_ENV.yourdoma.in"

export SLACK_API_URL="https://hooks.slack.com/services/xxx"

export DRONE_ADMIN='SOME REPO USER'
export DRONE_GITHUB_CLIENT=''
export DRONE_GITHUB_SECRET=''
export DRONE_SECRET='bla'

export KIBANA_PASSWORD=''

#export REG_HOST="reg.$CLUSTER_HOST"
export REGISTRY_HOST="localhost:5000"

export RBAC_ENABLE=true
export TLS_ENABLE=true
[ "$TLS_ENABLE" == "true" ] && TLSS=s
export TLSS

export HAS_CNI=false
export NOT_HAS_CNI=true
