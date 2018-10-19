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

printf "\n${COLOR_BLUE}[cluster] Creating secrets${COLOR_NC}\n"
k apply -f $valuesDir/secrets.yaml

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
helm init --service-account tiller --tiller-namespace=tiller --history-max 1

printf "${COLOR_PURPLE}[tiller]Waiting for Tiller to become available${COLOR_BROWN}\n"
k -n tiller rollout status -w deploy/tiller-deploy

if [ $ISLOCAL -eq 1 ]; then
	printf "\n${COLOR_BLUE}[cluster] Creating persistent volumes for ${CLUSTERTYPE}${COLOR_NC}\n"
	k apply -f "k8s/pvc-${CLUSTERTYPE}.yaml"
else
	. secrets/gce.sh
	printf "\n${COLOR_BLUE}[cluster] Creating persistent volumes for GCE${COLOR_NC}\n"
	k apply -f k8s/pvc-gce.yaml
fi

if [ "$KUBECONTEXT" == "minikube" ]; then
	# registry cache only for minikube, for simplicity as it has only one node to restore to, and docker env is already pointing to it
	printf "${COLOR_BLUE}[system] Deploying Docker Registry cache${COLOR_NC}\n"
	hs registry-cache charts/docker-registry -f $valuesDir/docker-registry-cache.yaml
	printf "${COLOR_PURPLE}[system] Waiting for Docker Registry caches to become available${COLOR_BROWN}\n"
	ks rollout status -w deploy/registry-cache-docker-registry
fi

###
### Registry available, go ahead with the rest !!
###

# Prometheus operator first needed for operator CRD's...ugh
printf "${COLOR_BLUE}[monitoring] Installing Prometheus Operator${COLOR_NC}\n"
hm prometheus-operator charts/prometheus-operator -f $valuesDir/prometheus-operator.yaml

# then nginx cause it fronts the registry server
printf "${COLOR_BLUE}[system] Deploying Nginx controller${COLOR_NC}\n"
hs nginx charts/nginx-ingress -f $valuesDir/nginx-ingress.yaml
printf "${COLOR_PURPLE}[system] Waiting for nginx to come online${COLOR_BROWN}\n"
ks rollout status -w deploy/nginx-ingress-nginx

if [ "$TLS_ENABLE" == "true" ]; then
	printf "${COLOR_BLUE}[system] Deploying CertManager${COLOR_NC}\n"
	hs cert-manager charts/cert-manager -f $valuesDir/cert-manager.yaml
fi

printf "${COLOR_BLUE}[system] Deploying Docker Registry${COLOR_NC}\n"
hs registry charts/docker-registry -f $valuesDir/docker-registry.yaml
printf "${COLOR_PURPLE}[system] Waiting for registry to come online${COLOR_BROWN}\n"
ks rollout status -w deploy/registry-cache-docker-registry

# now rook cluster
# printf "${COLOR_BLUE}[system] Deploying Rook Ceph operator first${COLOR_NC}\n"
# hi --namespace=rook-ceph-system rook-ceph charts/rook-ceph -f $valuesDir/rook-ceph.yaml

# printf "${COLOR_BLUE}[system] Deploying Rook Ceph cluster${COLOR_NC}\n"
# k apply -f k8s/rook-cluster.yaml
# k apply -f k8s/pvc-ceph.yaml
# k delete -f k8s/rook-cluster.yaml
# k delete -f k8s/pvc-ceph.yaml

printf "${COLOR_BLUE}[system] Deploying Kubernetes Dashboard${COLOR_NC}\n"
hsk dashboard charts/kubernetes-dashboard -f $valuesDir/dashboard.yaml

printf "${COLOR_BLUE}[system] Deploying Metrics Server${COLOR_NC}\n"
hsk metrics-server charts/metrics-server -f $valuesDir/metrics-server.yaml

# Prometheus system
printf "${COLOR_BLUE}[system] Installing Kube Prometheus with Alertmanager and Grafana for SYSTEM monitoring${COLOR_NC}\n"
hm prometheus charts/kube-prometheus -f $valuesDir/prometheus.yaml

#Prometheus team frontend
printf "${COLOR_BLUE}[system] Installing Prometheus and Alertmanager for TEAM-FRONTEND monitoring${COLOR_NC}\n"
htf team-frontend-prometheus charts/kube-prometheus -f $valuesDir/prometheus-team-frontend.yaml

if [ $ISLOCAL -eq 1 ]; then
	printf "${COLOR_BLUE}[logging] Deploying EFK stack\n${COLOR_NC}"
	# hl elasticsearch-operator charts/elasticsearch-operator # -f $valuesDir/efk.yaml
	# hl efk charts/efk -f $valuesDir/efk.yaml
	hl elk charts/elk -f $valuesDir/elk.yaml
	
	# for google fluentd-elasticsearch addon:
	# k label nodes kube-node-1 kube-node-2 beta.kubernetes.io/fluentd-ds-ready=true
	# k create -f $root/k8s/fluentd-elasticsearch/es-statefulset.yaml
	# k create -f $root/k8s/fluentd-elasticsearch/es-service.yaml
	# k create -f $root/k8s/fluentd-elasticsearch/fluentd-es-configmap.yaml
	# k create -f $root/k8s/fluentd-elasticsearch/fluentd-es-ds.yaml
	# k create -f $root/k8s/fluentd-elasticsearch/kibana-deployment.yaml
	# k create -f $root/k8s/fluentd-elasticsearch/kibana-service.yaml
	# k delete -f $root/k8s/fluentd-elasticsearch/es-statefulset.yaml
	# k delete -f $root/k8s/fluentd-elasticsearch/es-service.yaml
	# k delete -f $root/k8s/fluentd-elasticsearch/fluentd-es-configmap.yaml
	# k delete -f $root/k8s/fluentd-elasticsearch/fluentd-es-ds.yaml
	# k delete -f $root/k8s/fluentd-elasticsearch/kibana-deployment.yaml
	# k delete -f $root/k8s/fluentd-elasticsearch/kibana-service.yaml
fi

printf "${COLOR_BLUE}[system] Deploying Drone${COLOR_NC}\n"
hs drone charts/drone -f $valuesDir/drone.yaml

printf "${COLOR_BLUE}[system] Deploying Weave Scope${COLOR_NC}\n"
hs weave-scope charts/weave-scope -f $valuesDir/weave-scope.yaml

printf "${COLOR_WHITE}Now deploying TEAM FRONTEND packages${COLOR_NC}\n"

printf "${COLOR_BLUE}[team-frontend] Deploying RBAC${COLOR_NC}\n"
k apply -f k8s/rbac/team-frontend/drone-rbac.yaml

printf "${COLOR_BLUE}[team-frontend] Deploying Frontend API${COLOR_NC}\n"
htf team-frontend-api charts/api -f $valuesDir/api.yaml

if [ "$TLS_ENABLE" == "true" ]; then
	printf "${COLOR_PURPLE}[system] Waiting for cert-manager to become available${COLOR_BROWN}\n"
	ks rollout status -w deploy/cert-manager
fi

if [ "$TLS_ENABLE" == "true" ]; then
	printf "${COLOR_BLUE}[system] Deploying CertManager's ClusterIssuer (2-step deply for now)${COLOR_NC}\n"
	hs cert-manager-cluster-issuer charts/cert-manager-cluster-issuer -f $valuesDir/cert-manager-cluster-issuer.yaml
fi

printf "${COLOR_BLUE}Opening dashboards${COLOR_NC}\n"
sh bin/dashboards.sh

printf "${COLOR_WHITE}ALL DONE!${COLOR_NC}\n"
printf "${COLOR_WHITE}You might have to wait for cert manager handling incoming verifications for *.${CLUSTER_HOST} sites, triggering nginx reloads and making these sites accessible.${COLOR_NC}\n"
