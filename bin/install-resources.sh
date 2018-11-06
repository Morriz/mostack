#!/usr/bin/env bash
root=$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd .. && pwd)
. bin/colors.sh
shopt -s expand_aliases
. bin/aliases

sh bin/gen-values.sh

printf "${COLOR_WHITE}RUNNING INSTALL:${COLOR_NC}\n"

. $root/.env.sh
. secrets/${CLUSTER_PROVIDER}.sh
valuesDir="values/_gen/${CLUSTER_PROVIDER}"

printf "${COLOR_PURPLE}Waiting for a node to talk to"
until k get nodes >/dev/null 2>&1; do
	sleep 1
	printf "."
done

printf "\n${COLOR_WHITE}Now deploying Kubernetes resources\n"

printf "${COLOR_BLUE}[cluster] Setting up cluster resources like namespaces and RBAC${COLOR_NC}\n"
k apply -f k8s/cluster.yaml

printf "${COLOR_PURPLE}[cluster] Waiting for namespaces to become available"
until k get namespace tiller system monitoring logging team-frontend >/dev/null 2>&1; do
	sleep 1
	printf "."
done

# help calico: add extra namespace label for kube-system
k label namespace kube-system name=kube-system
k label namespace default name=default

if [ "$CLUSTERTYPE" == "minikube" ]; then
	printf "${COLOR_BLUE}[tiller] Installing Calico${COLOR_NC}\n"
	k apply -f k8s/calico-kdd/rbac.yaml
	k apply -f k8s/calico-kdd/calico.yaml

	printf "${COLOR_PURPLE}[tiller]Waiting for Calico to become available${COLOR_BROWN}\n"
	ksk rollout status -w daemonset.extensions/calico-node
fi

# @todo: add dind parts to policies and re-enable
# if [ "$CLUSTERTYPE" != "multinode" ]; then
# printf "${COLOR_BLUE}[tiller] Installing policies${COLOR_NC}\n"
# for ns in default kube-system system monitoring logging team-frontend; do k apply -n $ns -f k8s/policies/each-namespace/defaults.yaml; done
# k apply -f k8s/policies
# fi
# for ns in tiller default kube-system system monitoring logging team-frontend; do k apply -n $ns -f k8s/policies/each-namespace/allow-all.yaml; done

if [ "$KUBECONTEXT" == "dind" ]; then
	# delete broken setup
	ksk delete deploy/kubernetes-dashboard
fi

printf "${COLOR_BLUE}[tiller] Installing Tiller${COLOR_NC}\n"
# helm init --service-account tiller --tiller-namespace=tiller --history-max 1
helm init --service-account tiller --history-max 1

printf "${COLOR_PURPLE}[tiller]Waiting for Tiller to become available${COLOR_BROWN}\n"
ksk rollout status -w deploy/tiller-deploy

if [ $ISLOCAL -eq 1 ]; then
	printf "\n${COLOR_BLUE}[cluster] Creating persistent volumes for ${CLUSTERTYPE}${COLOR_NC}\n"
	k apply -f "k8s/pvc-${CLUSTERTYPE}.yaml"
else
	. secrets/gce.sh
	printf "\n${COLOR_BLUE}[cluster] Creating persistent volumes for GCE${COLOR_NC}\n"
	k apply -f k8s/pvc-gce.yaml
fi

printf "${COLOR_WHITE}ALL DONE!${COLOR_NC}\n"
