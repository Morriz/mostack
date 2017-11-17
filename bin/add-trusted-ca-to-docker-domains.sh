#!/usr/bin/env bash
root=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
. $root/colors.sh

[ -e $CLUSTER_HOST ] && printf "${COLOR_LIGHT_RED}CLUSTER_HOST not found in env! Please set as main domain for app subdomains.${COLOR_NC}" && exit 1

apps=(api grafana logging drone reg)
pem=`cat $root/fakelerootx1.pem`

caExists=`minikube ssh "echo '$pem' | tail -n +2 | head -n -1 | grep -f /etc/ssl/certs/ca-certificates.crt"`
if [ "$caExists" ]; then
  echo "LetsEncrypt staging CA already appended to /etc/ssl/certs/ca-certificates.crt, skipping..."
else
  echo "LetsEncrypt staging CA is not yet appended to /etc/ssl/certs/ca-certificates.crt in minikube, appending..."
  minikube ssh "echo \"$pem\" | sudo tee -a /etc/ssl/certs/ca-certificates.crt" > /dev/null
fi

for app in "${apps[@]}"
do
  domain="$app.$CLUSTER_HOST"
  echo "Copying LetsEncrypt staging CA to /etc/docker/certs.d/$domain/ca.cert in minikube..."
  minikube ssh "sudo mkdir -p /etc/docker/certs.d/$domain && echo \"$pem\" | sudo tee /etc/docker/certs.d/$domain/ca.crt" > /dev/null
done

minikube ssh "sudo systemctl restart docker"

echo "Ready!"
