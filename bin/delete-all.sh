#!/usr/bin/env bash
shopt -s expand_aliases
. bin/aliases

namespaces="system monitoring logging istio-system team-frontend"

function getPackages() {
    h list | awk '{print $1}' | tail -n +2 
}
packages=$(getPackages)

# ensure all helm packages are deleted
while [ "$packages" ]; do
    echo removing helm packages: $packages
	hk $packages > /dev/null 2>&1
	packages=$(getPackages)
done

# then force remove ghost pods
for ns in $namespaces; do 
    k -n $ns delete po --all --grace-period=0 --force > /dev/null 2>&1
done

# k delete ns $namespaces
# h reset --force
# k delete ns tiller
k delete -f k8s/calico-kdd/calico.yaml
# k delete -f k8s/calico-kdd/rbac.yaml
k delete pv --all

# helm delete still does not handle crd deletion
k delete crd --all

# but reinstall calico crds
k apply -f k8s/calico-kdd/calico.yaml


echo "CLEANED!"