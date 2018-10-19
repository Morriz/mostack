#!/usr/bin/env bash
root=$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd .. && pwd)
. bin/colors.sh
shopt -s expand_aliases
. bin/aliases
. secrets/minikube.sh

cd $root >/dev/null

sh bin/gen-values.sh

printf "${COLOR_WHITE}RUNNING INSTALL:${COLOR_NC}\n"

if [ -z "$1" ]; then
	k config use-context minikube
	valuesDir="/_gen/minikube"
else
	context=$(k config current-context)
	# when in right context, assing to var so we can autoswitch
	# export KUBE_CONTEXT=`k config current-context`
	if [ "$context" == "minikube" ] && [ -z "$KUBE_CONTEXT" ]; then
		echo "current context set to minikube and KUBE_CONTEXT not set!!"
		exit 1
	fi
	if [ -z "$KUBE_CONTEXT" ]; then
		echo "KUBE_CONTEXT not set!!"
		exit 1
	fi
	k config use-context $KUBE_CONTEXT
	valuesDir="/_gen/$1"
fi

isMini=0
which minikube >/dev/null 2>&1
[ $? -eq 0 ] && isMini=1
haveMiniRunning=0
minikube ip >/dev/null 2>&1
[ $? -eq 0 ] && haveMiniRunning=1

# osx only: install prerequisites if needed
if [ "$(uname -s)"=="Darwin" ]; then
	which helm >/dev/null
	if [ $? -ne 0 ]; then
		printf "${COLOR_BLUE}Installing helm${COLOR_NC}\n"
		[[ -x $(command -v helm) ]] || brew install helm
		printf "${COLOR_NC}"
	fi
fi

if [ $haveMiniRunning -ne 1 ]; then
	#  [ -e $CLUSTER_HOST ] && printf "${COLOR_LIGHT_RED}CLUSTER_HOST not found in env! Please set as main domain for app subdomains.${COLOR_NC}\n" && exit 1

	printf "${COLOR_BLUE}Starting minikube cluster${COLOR_NC}\n"
	sh bin/minikube-start.sh
	[ $? -ne 0 ] && printf "${COLOR_LIGHT_RED}Something went wrong starting minikube cluster${COLOR_NC}\n" && exit 1
	printf "${COLOR_NC}"

	# disabling while we use localhost:5000
	#  printf "${COLOR_BLUE}installing Letsencrypt Staging CA${COLOR_NC}\n"
	#  sh bin/add-trusted-ca-to-docker-domains.sh
	#  [ $? -ne 0 ] && printf "${COLOR_LIGHT_RED}Something went wrong installing Letsencrypt Staging CA${COLOR_NC}\n" && exit 1
	#  printf "${COLOR_NC}"
fi

printf "\n${COLOR_BLUE}Restoring docker images${COLOR_NC}\n"
. bin/restore-images.sh

printf "${COLOR_BLUE}Syncing clock${COLOR_NC}\n"
minikube ssh -- sudo ln -sf /usr/share/zoneinfo/Europe/Amsterdam /etc/localtime
minikube ssh -- docker run -i --rm --privileged --pid=host debian nsenter -t 1 -m -u -n -i date -u $(date -u +%m%d%H%M%Y)

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

printf "${COLOR_BLUE}[cluster] Creating secrets${COLOR_NC}\n"
k apply -f values$valuesDir/secrets.yaml

if [ $isMini -eq 1 ]; then
	printf "\n${COLOR_BLUE}[cluster] Creating persistent volume for minikube${COLOR_NC}\n"
	k apply -f k8s/pvc-minikube.yaml
	printf "${COLOR_BLUE}[cluster] Fixing RBAC access for minikube${COLOR_NC}\n"
	k apply -f k8s/rbac-minikube.yaml
else
	. secrets/gce.sh
	printf "\n${COLOR_BLUE}[cluster] Creating persistent volume for GCE${COLOR_NC}\n"
	k apply -f k8s/pvc-gce.yaml
fi

# remove taint that is not removed by kubeadm because of some race condition:
[ $haveMiniRunning -ne 1 ] && k taint node minikube node-role.kubernetes.io/master:NoSchedule- >/dev/null 2>&1
# help calico: add extra namespace label for kube-system
k label namespace kube-system name=kube-system
k label namespace default name=default

printf "${COLOR_BLUE}[tiller] Installing Calico${COLOR_NC}\n"
k apply -f k8s/calico-kdd/rbac.yaml
k apply -f k8s/calico-kdd/calico.yaml

printf "${COLOR_PURPLE}[tiller]Waiting for Calico to become available${COLOR_BROWN}\n"
ksk rollout status -w daemonset.extensions/calico-node

printf "${COLOR_BLUE}[tiller] Installing policies${COLOR_NC}\n"
for ns in default kube-system system monitoring logging team-frontend; do k apply -n $ns -f k8s/policies/each-namespace/defaults.yaml; done
k apply -f k8s/policies

printf "${COLOR_BLUE}[tiller] Installing Tiller${COLOR_NC}\n"
helm init --service-account tiller --tiller-namespace=tiller --history-max 1

printf "${COLOR_PURPLE}[tiller]Waiting for Tiller to become available${COLOR_BROWN}\n"
k -n tiller rollout status -w deploy/tiller-deploy

printf "${COLOR_BLUE}[system] Deploying Docker Registry cache first${COLOR_NC}\n"
hs registry-cache charts/docker-registry -f values$valuesDir/docker-registry-cache.yaml

printf "${COLOR_BLUE}[system] Deploying Kubernetes Dashboard${COLOR_NC}\n"
hsk dashboard charts/kubernetes-dashboard -f values$valuesDir/dashboard.yaml

printf "${COLOR_BLUE}[system] Deploying Metrics Server${COLOR_NC}\n"
hsk metrics-server charts/metrics-server -f values$valuesDir/metrics-server.yaml

printf "${COLOR_PURPLE}[system] Waiting for Docker Registry caches to become available${COLOR_BROWN}\n"
ks rollout status -w deploy/registry-cache-docker-registry

# Prometheus 
printf "${COLOR_BLUE}[monitoring] Installing Prometheus Operator${COLOR_NC}\n"
hm prometheus-operator charts/prometheus-operator -f values$valuesDir/prometheus-operator.yaml

printf "${COLOR_BLUE}[system] Installing Kube Prometheus (with Alertmanager and Grafana) for SYSTEM monitoring${COLOR_NC}\n"
hm prometheus charts/kube-prometheus -f values$valuesDir/prometheus.yaml

printf "${COLOR_BLUE}[system] Installing Prometheus and Alertmanager for TEAM-FRONTEND monitoring${COLOR_NC}\n"
htf team-frontend-prometheus charts/kube-prometheus -f values$valuesDir/prometheus-team-frontend.yaml
# END Prometheus 

printf "${COLOR_BLUE}[system] Deploying Nginx controller${COLOR_NC}\n"
hs nginx charts/nginx-ingress -f values$valuesDir/nginx-ingress.yaml

if [ "$TLS_ENABLE" == "true" ]; then
	printf "${COLOR_BLUE}[system] Deploying CertManager${COLOR_NC}\n"
	hs cert-manager charts/cert-manager -f values$valuesDir/cert-manager.yaml
fi

printf "${COLOR_BLUE}[system] Deploying Docker Registry${COLOR_NC}\n"
hs registry charts/docker-registry -f values$valuesDir/docker-registry.yaml

if [ $isMini -eq 1 ]; then
	printf "${COLOR_BLUE}[logging] Deploying EFK stack\n${COLOR_NC}"
	# hl elasticsearch-operator charts/elasticsearch-operator # -f values$valuesDir/efk.yaml
	# hl efk charts/efk -f values$valuesDir/efk.yaml
	hl elk charts/elk -f values$valuesDir/elk.yaml
fi

printf "${COLOR_BLUE}[system] Deploying Drone${COLOR_NC}\n"
hs drone charts/drone -f values$valuesDir/drone.yaml

printf "${COLOR_BLUE}[system] Deploying Weave Scope${COLOR_NC}\n"
hs weave-scope charts/weave-scope -f values$valuesDir/weave-scope.yaml

printf "${COLOR_WHITE}Now deploying TEAM FRONTEND packages${COLOR_NC}\n"

printf "${COLOR_BLUE}[team-frontend] Deploying RBAC${COLOR_NC}\n"
k apply -f k8s/rbac/team-frontend/drone-rbac.yaml

printf "${COLOR_BLUE}[team-frontend] Deploying Frontend API${COLOR_NC}\n"
htf team-frontend-api charts/api -f values$valuesDir/api.yaml

if [ "$TLS_ENABLE" == "true" ]; then
	printf "${COLOR_PURPLE}[system] Waiting for cert-manager to become available${COLOR_BROWN}\n"
	ks rollout status -w deploy/cert-manager
fi

if [ $isMini -eq 1 ]; then
	printf "${COLOR_BLUE}Starting tunnels${COLOR_NC}\n"
	sh bin/tunnel-to-minikube-ingress.sh
	sh bin/ngrok.sh
fi

if [ "$TLS_ENABLE" == "true" ]; then
	printf "${COLOR_BLUE}[system] Deploying CertManager's ClusterIssuer (2-step deply for now)${COLOR_NC}\n"
	hs cert-manager-cluster-issuer charts/cert-manager-cluster-issuer -f values$valuesDir/cert-manager-cluster-issuer.yaml
fi

printf "${COLOR_BLUE}Starting dashboard proxies${COLOR_NC}\n"
sh bin/dashboards.sh

printf "${COLOR_WHITE}ALL DONE!${COLOR_NC}\n"
