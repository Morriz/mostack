#!/usr/bin/env bash
root=$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd .. && pwd)
. $root/bin/colors.sh
shopt -s expand_aliases
. $root/bin/aliases

printf "${COLOR_WHITE}INSTALLING TILLER:${COLOR_NC}\n"

printf "${COLOR_PURPLE}Waiting for a node to talk to"
until k get nodes >/dev/null 2>&1; do
	sleep 1
	printf "."
done

printf "\n${COLOR_WHITE}Now deploying Kubernetes resources\n"

printf "${COLOR_BLUE}[cluster] Setting up tiller RBAC${COLOR_NC}\n"
k apply -f k8s/rbac/tiller.yaml

# help calico: add extra namespace label for kube-system
k label namespace kube-system name=kube-system
k label namespace default name=default
k create ns adm
k create ns system

if [ "$CLUSTERTYPE" = "minikube" ]; then
	printf "${COLOR_BLUE}[tiller] Installing Calico${COLOR_NC}\n"
	k apply -f k8s/calico-kdd/rbac.yaml
	k apply -f k8s/calico-kdd/calico.yaml

	printf "${COLOR_PURPLE}[tiller]Waiting for Calico to become available${COLOR_BROWN}\n"
	ksk rollout status -w daemonset.extensions/calico-node
fi

# @todo: fix policies and re-enable
# printf "${COLOR_BLUE}[tiller] Installing policies${COLOR_NC}\n"
# for ns in default kube-system system monitoring logging team-backend; do k apply -n $ns -f k8s/policies/each-namespace/defaults.yaml; done
# k apply -f k8s/policies

# for ns in default kube-system system monitoring logging team-backend; do k apply -n $ns -f k8s/policies/each-namespace/allow-all.yaml; done

printf "${COLOR_BLUE}[tiller] Installing Tiller${COLOR_NC}\n"
if [ ! -d "$root/tls" ]; then
	sh $root/bin/gen-tiller-certs.sh
fi
ks create secret tls helm-client --cert=./tls/flux-helm-operator.pem --key=./tls/flux-helm-operator-key.pem
helm init --upgrade --service-account tiller \
	--override 'spec.template.spec.containers[0].command'='{/tiller,--storage=secret}' \
	--tiller-tls \
	--tiller-tls-cert ./tls/server.pem \
	--tiller-tls-key ./tls/server-key.pem \
	--tiller-tls-verify \
	--tls-ca-cert ./tls/ca.pem \
	--history-max 2

printf "${COLOR_PURPLE}[tiller]Waiting for Tiller to become available${COLOR_BROWN}\n"
ksk rollout status -w deploy/tiller-deploy

# if [ "$CLUSTERTYPE" = "minikube" ]; then
# 	printf "\n${COLOR_BLUE}[cluster] Creating persistent volumes for minikube${COLOR_NC}\n"
# 	k apply -f "k8s/pv-minikube.yaml"
# else
# 	. secrets/gce.sh
# 	printf "\n${COLOR_BLUE}[cluster] Creating persistent volumes for GCE${COLOR_NC}\n"
# 	k apply -f k8s/pv-gce.yaml
# fi

printf "${COLOR_BLUE}[cluster] Installing needed CRDs and other prerequisites${COLOR_NC}\n"

hi --namespace=adm sealed-secrets stable/sealed-secrets

ks apply -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.6/deploy/manifests/00-crds.yaml
k label namespace system certmanager.k8s.io/disable-validation="true"

k apply -f https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.7.0/sealedsecret-crd.yaml

k apply -f https://raw.githubusercontent.com/coreos/prometheus-operator/master/example/prometheus-operator-crd/alertmanager.crd.yaml
k apply -f https://raw.githubusercontent.com/coreos/prometheus-operator/master/example/prometheus-operator-crd/prometheus.crd.yaml
k apply -f https://raw.githubusercontent.com/coreos/prometheus-operator/master/example/prometheus-operator-crd/prometheusrule.crd.yaml
k apply -f https://raw.githubusercontent.com/coreos/prometheus-operator/master/example/prometheus-operator-crd/servicemonitor.crd.yaml

if [ -f tls/server-key.pem ]; then
	ks create secret generic flux-git-deploy --from-file=identity=tls/server-key.pem
fi
printf "${COLOR_WHITE}ALL DONE!${COLOR_NC}\n"
