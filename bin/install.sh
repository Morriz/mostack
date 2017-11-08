#!/usr/bin/env bash
root=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )
. $root/bin/colors.sh
shopt -s expand_aliases
. $root/bin/aliases

printf "${COLOR_WHITE}RUNNING INSTALL:${COLOR_NC}\n"

isMini=0
which minikube > /dev/null 2>&1
[ $? -eq 0 ] && isMini=1
haveMiniRunning=0
minikube ip > /dev/null 2>&1
[ $? -eq 0 ] && haveMiniRunning=1

# osx only: install prerequisites if needed
if [ "`uname -s`"=="Darwin" ]; then
  which helm > /dev/null
  if [ $? -ne 0 ]; then
    printf "${COLOR_BLUE}Installing helm${COLOR_GREEN}\n"
    [[ -x `command -v helm` ]] || brew install helm
    printf "${COLOR_NC}"
  fi
fi

if [ $haveMiniRunning -ne 1 ]; then
#  [ -e $CLUSTER_HOST ] && printf "${COLOR_LIGHT_RED}CLUSTER_HOST not found in env! Please set as main domain for app subdomains.${COLOR_NC}\n" && exit 1

  printf "${COLOR_BLUE}Starting minikube cluster${COLOR_GREEN}\n"
  sh $root/bin/minikube-start.sh
  [ $? -ne 0 ] && printf "${COLOR_LIGHT_RED}Something went wrong starting minikube cluster${COLOR_NC}\n" && exit 1
  printf "${COLOR_NC}"

# disabling while we use localhost:5000
#  printf "${COLOR_BLUE}installing Letsencrypt Staging CA${COLOR_GREEN}\n"
#  sh $root/bin/add-trusted-ca-to-docker-domains.sh
#  [ $? -ne 0 ] && printf "${COLOR_LIGHT_RED}Something went wrong installing Letsencrypt Staging CA${COLOR_NC}\n" && exit 1
#  printf "${COLOR_NC}"
fi

printf "${COLOR_PURPLE}Waiting for a node to talk to"
until k get nodes > /dev/null 2>&1; do sleep 1; printf "."; done

printf "\n${COLOR_PURPLE}Waiting for kubernetes to listen"
until ks rollout status -w deployment/kube-dns > /dev/null 2>&1; do sleep 1; printf "."; done

#printf "${COLOR_BLUE}deploying istio\n${COLOR_GREEN}"
#k apply -f $root/k8s/istio/istio-auth.yaml
#k apply -f $root/k8s/istio/istio-initializer.yaml
#k apply -f $root/k8s/istio/addons/
#[ $? -ne 0 ] && printf "${COLOR_LIGHT_RED}Something went wrong installing istio${COLOR_NC}\n" && exit 1
#printf "${COLOR_NC}"

#printf "${COLOR_BLUE}Applying RBAC for minikube asap\n${COLOR_GREEN}"
#k apply -f $root/k8s/minikube-rbac.yaml

printf "\n${COLOR_BLUE}[CLUSTER] Installing namespaces${COLOR_GREEN}\n"
k create namespace "dev" > /dev/null 2>&1
k create namespace "monitoring" > /dev/null 2>&1
k create namespace "drone" > /dev/null 2>&1

printf "${COLOR_PURPLE}[CLUSTER] Waiting for namespaces to become available"
until k get namespace dev monitoring drone > /dev/null 2>&1; do sleep 1; printf "."; done

printf "\n${COLOR_BLUE}[CLUSTER] Creating persistent volume\n${COLOR_GREEN}"
k apply -f $root/k8s/pvc.yaml

printf "${COLOR_BLUE}[KUBE-SYSTEM] Deploying Docker Registry cache first${COLOR_GREEN}\n"
helm template -n system-cache $root/charts/docker-registry -f $root/values/docker-registry-cache.yaml | ks apply -f -
[ $? -ne 0 ] && printf "${COLOR_LIGHT_RED}Something went wrong installing Docker Registry cache${COLOR_NC}\n" && exit 1

printf "${COLOR_PURPLE}[KUBE-SYSTEM] Waiting for Docker Registry cache to become available${COLOR_BROWN}\n"
ks rollout status -w deployment/system-cache-docker-registry

#printf "${COLOR_BLUE}deploying nginx controller\n${COLOR_GREEN}"
#helm template -n system $root/charts/nginx-ingress -f $root/values/nginx-ingress.yaml | k apply -f -
#[ $? -ne 0 ] && printf "${COLOR_LIGHT_RED}Something went wrong installing nginx controller${COLOR_NC}\n" && exit 1
#printf "${COLOR_NC}"
#
#printf "${COLOR_BLUE}waiting for nginx controller to become available${COLOR_BROWN}\n"
#k rollout status -w deployment/system-nginx-ingress-controller
#printf "${COLOR_NC}"

printf "${COLOR_BLUE}[MONITORING] Installing Prometheus Operator${COLOR_GREEN}\n"
helm template -n system $root/charts/prometheus-operator -f $root/values/prometheus-operator.yaml | km apply -f -

printf "${COLOR_PURPLE}[MONITORING] Waiting for Prometheus Operator to register custom resource definitions"
until km get customresourcedefinitions servicemonitors.monitoring.coreos.com > /dev/null 2>&1; do sleep 1; printf "."; done
until km get customresourcedefinitions prometheuses.monitoring.coreos.com > /dev/null 2>&1; do sleep 1; printf "."; done
until km get customresourcedefinitions alertmanagers.monitoring.coreos.com > /dev/null 2>&1; do sleep 1; printf "."; done
until km get servicemonitors.monitoring.coreos.com > /dev/null 2>&1; do sleep 1; printf "."; done
until km get prometheuses.monitoring.coreos.com > /dev/null 2>&1; do sleep 1; printf "."; done
until km get alertmanagers.monitoring.coreos.com > /dev/null 2>&1; do sleep 1; printf "."; done

printf "\n${COLOR_BLUE}[KUBE_SYSTEM] Installing Kube exporters for Prometheus consumption${COLOR_GREEN}\n"
helm template -n system $root/charts/kube-prometheus -f $root/values/kube-prometheus.yaml --set onlyServices=true | k apply -f -

printf "${COLOR_BLUE}[MONITORING] Installing Prometheus, Alertmanager and Grafana${COLOR_GREEN}\n"
helm template -n system $root/charts/prometheus -f $root/values/prometheus.yaml | k apply -f -
helm template -n team-frontend $root/charts/prometheus -f $root/values/prometheus-team-frontend.yaml | k apply -f -
helm template -n system $root/charts/alertmanager -f $root/values/alertmanager.yaml | k apply -f -
helm template -n team-frontend $root/charts/alertmanager -f $root/values/alertmanager-team-frontend.yaml | k apply -f -
helm template -n system $root/charts/grafana -f $root/values/grafana.yaml | km apply -f -

printf "${COLOR_BLUE}[KUBE-SYSTEM] Deploying Kube Lego${COLOR_GREEN}\n"
helm template -n system $root/charts/kube-lego -f $root/values/kube-lego.yaml | ks apply -f -

printf "${COLOR_BLUE}[KUBE-SYSTEM] Deploying Docker Registry${COLOR_GREEN}\n"
helm template -n system $root/charts/docker-registry -f $root/values/docker-registry.yaml | ks apply -f -

printf "${COLOR_BLUE}[DRONE] Deploying Drone${COLOR_GREEN}\n"
helm template -n system $root/charts/drone -f $root/values/drone.yaml | kd apply -f -

printf "${COLOR_BLUE}[DEFAULT] Deploying API${COLOR_GREEN}\n"
helm template -n team-frontend $root/charts/api -f $root/values/api.yaml | k apply -f -
[ $? -ne 0 ] && printf "${COLOR_LIGHT_RED}Something went wrong installing app charts${COLOR_NC}\n" && exit 1

printf "${COLOR_BLUE}[LOGGING] Deploying ELK stack\n${COLOR_GREEN}"
k apply -f $root/k8s/elk/

printf "${COLOR_PURPLE}[KUBE-SYSTEM] Waiting for kube-lego to become available${COLOR_BROWN}\n"
ks rollout status -w deployment/system-kube-lego

printf "${COLOR_BLUE}Starting tunnels${COLOR_NC}\n"
# and run tunnel to minikube node's port 80 and 443
[ ! -z $isMini ]  && sh $root/bin/tunnel-to-minikube-ingress.sh

printf "${COLOR_WHITE}ALL DONE!${COLOR_NC}\n"
