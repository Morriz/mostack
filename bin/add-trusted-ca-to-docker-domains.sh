#!/usr/bin/env bash
root=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
. $root/colors.sh

[ -e $CLUSTER_HOST ] && printf "${COLOR_LIGHT_RED}CLUSTER_HOST not found in env! Please set as main domain for app subdomains.${COLOR_NC}" && exit 1

apps=(api drone reg)

cat $root/fakelerootx1.pem | minikube ssh "grep -f /etc/ssl/certs/ca-certificates.crt < /dev/null 2>&1" > /dev/null
if [ $? -ne 0 ]; then
  echo "LetsEncrypt staging CA is not yet appended to /etc/ssl/certs/ca-certificates.crt in minikube, appending..."
  cat $root/fakelerootx1.pem | minikube ssh "sudo tee -a /etc/ssl/certs/ca-certificates.crt < /dev/null 2>&1" > /dev/null
fi

for app in "${apps[@]}"
do
  domain="$app.$CLUSTER_HOST"
  echo "Copying LetsEncrypt staging CA to /etc/docker/certs.d/$domain/ca.cert in minikube..."
  cat $root/fakelerootx1.pem | minikube ssh "sudo mkdir -p /etc/docker/certs.d/$domain && sudo tee /etc/docker/certs.d/$domain/ca.crt < /dev/null 2>&1" > /dev/null
done

echo "Ready!"
