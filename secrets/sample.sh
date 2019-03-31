#!/usr/bin/env bash

export MINIKUBE_IP='192.168.99.100'
export NGROK_TOKEN=''

export LETSENCRYPT_EMAIL='you@yourdoma.in'

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
if [ "$TLS_ENABLE" == "true" ]; then
    TLSS=s
    export TLS_DISABLE=false
    export DRONE_GITHUB_CLIENT='' # your.doma.in secure
    export DRONE_GITHUB_SECRET='' # your.doma.in secure
else
    export TLS_DISABLE=true
    export DRONE_GITHUB_CLIENT='' # your.doma.in insecure
    export DRONE_GITHUB_SECRET='' # your.doma.in insecure
fi
export TLSS
