#!/usr/bin/env bash

export MINIKUBE_IP='192.168.99.100'
export NGROK_TOKEN=''

export LETSENCRYPT_EMAIL='you@yourdoma.in'
export LETSENCRYPT_STAGE=staging # prod

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
export TLS_DISABLE=true
iif [ "$TLS_ENABLE" == "true" ]; then
    TLSS=s
    export TLS_DISABLE=false
else
    export TLS_DISABLE=true
fi
export TLSS

export HAS_CNI=true
export NOT_HAS_CNI=false
