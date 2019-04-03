#!/usr/bin/env bash

export NGROK_TOKEN=''

export LETSENCRYPT_EMAIL='you@yourdoma.in'

export CLUSTER_ENV=dev
export CLUSTER_HOST="$CLUSTER_ENV.yourdoma.in"

export SLACK_API_URL="https://hooks.slack.com/services/xxx"

export DRONE_ADMIN='SOME REPO USER'
export DRONE_GITHUB_CLIENT_ID=''
export DRONE_GITHUB_CLIENT_SECRET=''
export DRONE_SECRET='blabla'

export KIBANA_PASSWORD=$(htpasswd -nb admin jaja | base64 -w 0)
export GRAFANA_PASSWORD='jaja'

#export REG_HOST="reg.$CLUSTER_HOST"
export REGISTRY_HOST="localhost:5000"

export RBAC_ENABLE=true
export TLS_ENABLE=true
if [ "$TLS_ENABLE" = "true" ]; then
    TLSS=s
    export TLS_DISABLE=false
    export DRONE_GITHUB_CLIENT_ID=''     # your.doma.in secure
    export DRONE_GITHUB_CLIENT_SECRET='' # your.doma.in secure
else
    export TLS_DISABLE=true
    export DRONE_GITHUB_CLIENT_ID=''     # your.doma.in insecure
    export DRONE_GITHUB_CLIENT_SECRET='' # your.doma.in insecure
fi
export TLSS
