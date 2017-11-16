#!/usr/bin/env bash
root=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )
. $root/bin/colors.sh

# start minikube cluster

# with localkube:
#minikube start \
#    --kubernetes-version v1.7.5 \
#    --extra-config=apiserver.Authorization.Mode=RBAC \
#    --extra-config=apiserver.Admission.PluginNames="NamespaceLifecycle,LimitRanger,ServiceAccount,PersistentVolumeLabel,DefaultStorageClass,ResourceQuota,DefaultTolerationSeconds" \
#    --registry-mirror=http://localhost:6000 \
#    --registry-mirror=http://localhost:6001

# with kubeadm bootstrapper:
minikube start \
    --kubernetes-version v1.8.3 \
    --bootstrapper kubeadm \
    --extra-config=apiserver.admission-control="Initializers,NamespaceLifecycle,LimitRanger,ServiceAccount,DefaultStorageClass,GenericAdmissionWebhook,ResourceQuota,PodPreset" \
    --registry-mirror=http://localhost:6000 \
    --registry-mirror=http://localhost:6001

#    --v 10 \

# timesync
printf "${COLOR_BLUE}ON MINIKUBE: syncing clock${COLOR_NC}\n"
minikube ssh -- sudo ln -sf /usr/share/zoneinfo/Europe/Amsterdam /etc/localtime
minikube ssh -- docker run -i --rm --privileged --pid=host debian nsenter -t 1 -m -u -n -i date -u $(date -u +%m%d%H%M%Y)

# add to wakeup script after `brew install sleepwatcher && brew services start sleepwatcher`:
# echo minikube ssh -- docker run -i --rm --privileged --pid=host debian nsenter -t 1 -m -u -n -i date -u $(date -u +%m%d%H%M%Y) > ~/.wakeup
