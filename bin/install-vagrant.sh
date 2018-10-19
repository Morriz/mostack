#!/usr/bin/env bash
export CLUSTERTYPE=multinode

vagrant up
. ./.env.sh
. secrets/local.sh
vagrant ssh kube-master -c "cat .kube/config" > ~/.kube/config-vagrant
KUBECONFIG=~/.kube/config:~/.kube/config-vagrant kubectl config view --flatten > ~/.kube/config
kubectl config use-context kubernetes 
# . bin/add-trusted-ca-to-docker-domains.sh
