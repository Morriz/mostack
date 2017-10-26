#!/usr/bin/env bash
root=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )
. $root/bin/colors.sh
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
    printf "${COLOR_BLUE}installing helm${COLOR_GREEN}\n"
    [[ -x `command -v helm` ]] || brew install helm
    printf "${COLOR_NC}"
  fi
fi

#helm plugin list | grep template > /dev/null
#if [ $? -ne 0 ]; then
#  printf "${COLOR_BLUE}installing helm template plugin${COLOR_GREEN}\n"
#  helm plugin install https://github.com/technosophos/helm-template
#  printf "${COLOR_NC}"
#fi

if [ $haveMiniRunning -ne 1 ]; then
  [ -e $CLUSTER_HOST ] && printf "${COLOR_LIGHT_RED}CLUSTER_HOST not found in env! Please set as main domain for app subdomains.${COLOR_NC}\n" && exit 1

  printf "${COLOR_BLUE}starting minikube cluster${COLOR_GREEN}\n"
  sh $root/bin/minikube-start.sh
  [ $? -ne 0 ] && printf "${COLOR_LIGHT_RED}Something went wrong starting minikube cluster${COLOR_NC}\n" && exit 1
  printf "${COLOR_NC}"

# disabling while we use localhost:5000
#  printf "${COLOR_BLUE}installing Letsencrypt Staging CA${COLOR_GREEN}\n"
#  sh $root/bin/add-trusted-ca-to-docker-domains.sh
#  [ $? -ne 0 ] && printf "${COLOR_LIGHT_RED}Something went wrong installing Letsencrypt Staging CA${COLOR_NC}\n" && exit 1
#  printf "${COLOR_NC}"
fi

kubectl get nodes | grep Ready &> /dev/null
printf "${COLOR_BLUE}waiting for a node to talk to${COLOR_BROWN}\n"
until [ $? -eq 0 ]; do
  echo "waiting 3 seconds..."
  sleep 3
  kubectl get nodes | grep Ready &> /dev/null
done
printf "${COLOR_NC}"

printf "${COLOR_BLUE}waiting for kubernetes to listen${COLOR_BROWN}\n"
kubectl rollout status -w deployment/kube-dns -n kube-system &> /dev/null
until [ $? -eq 0 ]; do
  echo "no response, waiting 10 secs..."
  sleep 10
  kubectl rollout status -w deployment/kube-dns -n kube-system &> /dev/null
done
printf "${COLOR_NC}"

#printf "${COLOR_BLUE}deploying istio\n${COLOR_GREEN}"
#kubectl apply -f $root/k8s/istio/istio-auth.yaml
#kubectl apply -f $root/k8s/istio/istio-initializer.yaml
#kubectl apply -f $root/k8s/istio/addons/
#[ $? -ne 0 ] && printf "${COLOR_LIGHT_RED}Something went wrong installing istio${COLOR_NC}\n" && exit 1
#printf "${COLOR_NC}"

printf "${COLOR_BLUE}claiming persistent volume\n${COLOR_GREEN}"
kubectl apply -f $root/k8s/pvc.yaml
printf "${COLOR_NC}"

printf "${COLOR_BLUE}deploying registry cache chart first\n${COLOR_GREEN}"
helm template -n mostack-cache $root/charts/docker-registry -f $root/values/docker-registry-cache.yaml | kubectl apply -f -
[ $? -ne 0 ] && printf "${COLOR_LIGHT_RED}Something went wrong installing registry cache chart${COLOR_NC}\n" && exit 1
printf "${COLOR_NC}"

printf "${COLOR_BLUE}waiting for registry cache to become available${COLOR_BROWN}\n"
kubectl rollout status -w deployment/mostack-cache-docker-registry
printf "${COLOR_NC}"

printf "${COLOR_BLUE}now deploying rest of the local charts\n${COLOR_GREEN}"
helm template -n mostack $root/charts/kube-lego -f $root/values/kube-lego.yaml | kubectl apply -f -
helm template -n mostack $root/charts/docker-registry -f $root/values/docker-registry.yaml | kubectl apply -f -
helm template -n mostack $root/charts/drone -f $root/values/drone.yaml | kubectl apply -f -
helm template -n mostack $root/charts/api -f $root/values/api.yaml | kubectl apply -f -
helm template -n mostack $root/charts/prometheus -f $root/values/prometheus.yaml | kubectl apply -f -
kubectl delete jobs/mostack-grafana-set-datasource > /dev/null
helm template -n mostack $root/charts/grafana -f $root/values/grafana.yaml | kubectl apply -f -
[ $? -ne 0 ] && printf "${COLOR_LIGHT_RED}Something went wrong installing app charts${COLOR_NC}\n" && exit 1
printf "${COLOR_NC}"

printf "${COLOR_BLUE}now deploying extra k8s/ files\n${COLOR_GREEN}"
#sh $root/bin/helm-remotes.sh
sh $root/bin/logging.sh
printf "${COLOR_NC}"

printf "${COLOR_BLUE}waiting for kube-lego to become available${COLOR_BROWN}\n"
kubectl rollout status -w deployment/mostack-kube-lego
printf "${COLOR_NC}"

printf "${COLOR_BLUE}starting tunnels${COLOR_NC}\n"
# and run tunnel to minikube node's port 80 and 443
[ ! -z $isMini ]  && sh $root/bin/tunnel-to-minikube-ingress.sh

printf "${COLOR_WHITE}ALL DONE!${COLOR_NC}\n"
