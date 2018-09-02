#!/usr/bin/env bash
root=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )
. $root/bin/colors.sh

# start minikube cluster

# with localkube:
# minikube start \
#     --kubernetes-version v1.8.0 \
#     --extra-config=apiserver.Authorization.Mode=RBAC \
#     --extra-config=apiserver.Admission.PluginNames="NamespaceLifecycle,LimitRanger,ServiceAccount,PersistentVolumeLabel,DefaultStorageClass,ResourceQuota,DefaultTolerationSeconds,GenericAdmissionWebhook,PodPreset" \
#     --network-plugin=cni \
#     --host-only-cidr 172.17.17.1/24 \
#     --extra-config=kubelet.PodCIDR=192.168.0.0/16 \
#     --extra-config=proxy.ClusterCIDR=192.168.0.0/16 \
#     --extra-config=controller-manager.ClusterCIDR=192.168.0.0/16 \
#     --extra-config=controller-manager.CIDRAllocatorType=RangeAllocator \
#     --extra-config=controller-manager.AllocateNodeCIDRs=true \
#     --registry-mirror=http://localhost:6000

# with kubeadm bootstrapper:
minikube -v 10 start \
   --bootstrapper kubeadm \
   --kubernetes-version v1.11.2 \
   --network-plugin=cni --extra-config=kubelet.network-plugin=cni \
   --host-only-cidr=172.17.17.1/24 \
   --extra-config=apiserver.enable-admission-plugins="NamespaceLifecycle,LimitRanger,ServiceAccount,DefaultStorageClass,DefaultTolerationSeconds,MutatingAdmissionWebhook,ValidatingAdmissionWebhook,ResourceQuota" \
   --extra-config=apiserver.runtime-config=batch/v2alpha1=true \
   --extra-config=kubelet.authentication-token-webhook=true --extra-config=kubelet.authorization-mode=Webhook \
   --extra-config=scheduler.address=0.0.0.0 --extra-config=controller-manager.address=0.0.0.0 \
   --extra-config=controller-manager.cluster-cidr=192.168.0.0/16 --extra-config=controller-manager.allocate-node-cidrs=true \
   --registry-mirror=http://localhost:6000
#    --extra-config=controller-manager.pod-network-cidr=192.168.0.0/16 \
#    --extra-config=proxy.cluster-cidr=192.168.0.0/16 \

# add to wakeup script after `brew install sleepwatcher && brew services start sleepwatcher`:
# echo minikube ssh -- docker run -i --rm --privileged --pid=host debian nsenter -t 1 -m -u -n -i date -u $(date -u +%m%d%H%M%Y) > ~/.wakeup
