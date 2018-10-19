#!/usr/bin/env bash
root=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
. $root/colors.sh

[ -e $CLUSTER_HOST ] && printf "${COLOR_LIGHT_RED}CLUSTER_HOST not found in env! Please set as main domain for app subdomains.${COLOR_NC}" && exit 1

apps=(api grafana logging drone reg)
pem=`cat $root/fakelerootx1.pem`

if [ "$CLUSTERTYPE" == "minikube" ]; then
  cmd='minikube ssh'
  caExists=`$cmd "echo '$pem' | tail -n +2 | head -n -1 | grep -f /etc/ssl/certs/ca-certificates.crt"`
else
  cmd='vagrant ssh'
  caExists=`$cmd kube-master -c "echo '$pem' | tail -n +2 | head -n -1 | grep -f /etc/ssl/certs/ca-certificates.crt"`
fi  

if [ "$caExists" ]; then
  echo "LetsEncrypt staging CA already appended to /etc/ssl/certs/ca-certificates.crt, skipping..."
else
  echo "LetsEncrypt staging CA is not yet appended to /etc/ssl/certs/ca-certificates.crt in kube nodes, appending..."
  if [ "$CLUSTERTYPE" == "minikube" ]; then
    $cmd "echo \"$pem\" | sudo tee -a /etc/ssl/certs/ca-certificates.crt" > /dev/null
    $cmd "sudo systemctl restart docker"
  else
    nodes=(kube-master kube-node-1 kube-node-2)
    for node in "${nodes[@]}"
    do
      $cmd $node -c "echo \"$pem\" | sudo tee -a /etc/ssl/certs/ca-certificates.crt" > /dev/null
      $cmd $node -c "sudo systemctl restart docker"
    done
  fi 
fi

echo "Ready!"
