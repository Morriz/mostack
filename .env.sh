#!/usr/bin/env bash
export KUBECONTEXT=`kubectl config current-context`

local=(minikube dind kubernetes)
if [[ " ${local[@]} " =~ " ${KUBECONTEXT} " ]]; then
    export ISLOCAL=1
    export CLUSTER_PROVIDER=local
else
    export CLUSTER_PROVIDER=gce
fi

if [ "$KUBECONTEXT" == "minikube" ]; then 
    export CLUSTERTYPE=minikube
    export ISMINIKUBE=true
    export NOTISMINIKUBE=false
    export HAS_KUBE_DNS=false
    export HAS_COREDNS=true
else
    export CLUSTERTYPE=multinode
    export ISMINIKUBE=false
    export NOTISMINIKUBE=true
    export HAS_KUBE_DNS=true
    export HAS_COREDNS=false
fi

if [ "$KUBECONTEXT" == "dind" ]; then 
    export CONTAINERS_LOCATION=/dind/docker/containers
    export K8SCORECOMPONENTS_NAMESPACE=default
else
    export CONTAINERS_LOCATION=/var/lib/docker/containers
    export K8SCORECOMPONENTS_NAMESPACE=kube-system
fi