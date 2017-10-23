#!/usr/bin/env bash
root=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )

# start minikube cluster
minikube start \
    --extra-config=apiserver.Admission.PluginNames="Initializers,NamespaceLifecycle,LimitRanger,ServiceAccount,DefaultStorageClass,GenericAdmissionWebhook,ResourceQuota" \
    --kubernetes-version=v1.7.5 \
    --registry-mirror="http://localhost:6000"

# timesync
minikube ssh -- sudo ln -sf /usr/share/zoneinfo/Europe/Amsterdam /etc/localtime
minikube ssh -- docker run -i --rm --privileged --pid=host debian nsenter -t 1 -m -u -n -i date -u $(date -u +%m%d%H%M%Y)

# add to wakeup script after `brew install sleepwatcher && brew services start sleepwatcher`:
# echo minikube ssh -- docker run -i --rm --privileged --pid=host debian nsenter -t 1 -m -u -n -i date -u $(date -u +%m%d%H%M%Y) > ~/.wakeup
