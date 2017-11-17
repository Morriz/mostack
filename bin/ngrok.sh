#!/usr/bin/env bash
root=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )
. $root/bin/colors.sh
shopt -s expand_aliases
. $root/bin/aliases
. $root/bin/functions.sh
. $root/secrets/minikube.sh

# uses 'mo'
which mo > /dev/null
if [ $? -ne 0 ]; then
  echo "'mo' needs to be installed:"
  echo "curl https://raw.githubusercontent.com/tests-always-included/mo/master/mo -o mo&& chmod u+x mo && mv mo /usr/local/bin)"
  exit 1
fi

killall ngrok
cat $root/templates/ngrok.yaml | mo > /tmp/ngrok.yaml
ngrok start -config=/tmp/ngrok.yaml dev dev-tls &
