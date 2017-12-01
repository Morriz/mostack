#!/usr/bin/env bash
root=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )
. $root/bin/colors.sh

# start minikube cluster

# with localkube:
minikube start \
    --kubernetes-version v1.8.0 \
    --extra-config=apiserver.Authorization.Mode=RBAC \
    --extra-config=apiserver.Admission.PluginNames="NamespaceLifecycle,LimitRanger,ServiceAccount,PersistentVolumeLabel,DefaultStorageClass,ResourceQuota,DefaultTolerationSeconds,GenericAdmissionWebhook,PodPreset" \
    --network-plugin=cni \
    --host-only-cidr 172.17.17.1/24 \
    --extra-config=kubelet.PodCIDR=192.168.0.0/16 \
    --extra-config=proxy.ClusterCIDR=192.168.0.0/16 \
    --extra-config=controller-manager.ClusterCIDR=192.168.0.0/16 \
    --extra-config=controller-manager.CIDRAllocatorType=RangeAllocator \
    --extra-config=controller-manager.AllocateNodeCIDRs=true \
    --registry-mirror=http://localhost:6000

# with kubeadm bootstrapper:
#minikube start \
#    --bootstrapper kubeadm \
#    --kubernetes-version v1.8.4 \
#    --extra-config=apiserver.admission-control="NamespaceLifecycle,LimitRanger,ServiceAccount,PersistentVolumeLabel,DefaultStorageClass,ResourceQuota,DefaultTolerationSeconds,GenericAdmissionWebhook,PodPreset" \
#    --network-plugin=cni \
#    --host-only-cidr 172.17.17.1/24 \
#    --extra-config=kubelet.pod-cidr=192.168.0.0/16 \
#    --extra-config=proxy.cluster-cidr=192.168.0.0/16 \
#    --extra-config=controller-manager.cluster-cidr=192.168.0.0/16 \
#    --extra-config=controller-manager.cidr-allocator-type=RangeAllocator \
#    --extra-config=controller-manager.allocate-node-cidrs=true \
#    --registry-mirror=http://localhost:6000

#    --v 10 \

# add to wakeup script after `brew install sleepwatcher && brew services start sleepwatcher`:
# echo minikube ssh -- docker run -i --rm --privileged --pid=host debian nsenter -t 1 -m -u -n -i date -u $(date -u +%m%d%H%M%Y) > ~/.wakeup
