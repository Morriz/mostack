#!/usr/bin/env bash

export NGROK_TOKEN=''

export LETSENCRYPT_EMAIL='you@yourdoma.in'

export CLUSTER_ENV=dev
export CLUSTER_HOST="$CLUSTER_ENV.yourdoma.in"

export SLACK_API_URL="https://hooks.slack.com/services/xxx"

export DRONE_ADMIN='SOME EXISTING GIT USER'
export DRONE_GITHUB_CLIENT_ID=''
export DRONE_GITHUB_CLIENT_SECRET=''
export DRONE_GITHUB_CLIENT_SECRET_BASE64=$(echo -n $DRONE_GITHUB_CLIENT_SECRET | base64 -w 0)
export DRONE_PROMETHEUS_AUTH_TOKEN=

export KIBANA_PASSWORD= # htpasswd -nb admin jaja | base64 -w 0
export GRAFANA_PASSWORD='jaja'

export REGISTRY_HOST="reg.$CLUSTER_HOST"
export REG_USER=drone
export REG_PASS=blabla
export REGISTRY_HTPASSWD= # htpasswd -nb $REG_USER $REG_PASS
export REGISTRY_SHARED_SECRET=

export RBAC_ENABLE=true