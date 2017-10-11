#!/usr/bin/env bash
root=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )
. $root/bin/colors.sh
. $root/bin/aliases

printf "${COLOR_WHITE}RUNNING INSTALL:${COLOR_NC}\n"

# set following to 0 if necessary:
isMini=1
haveMiniRunning=1

# osx only: install prerequisites if needed
if [ "`uname -s`"=="Darwin" ]; then
  [[ -x `command -v helm` ]] || brew install helm
fi

if [ $haveMiniRunning -ne 1 ]; then
  [ -e $CLUSTER_HOST ] && printf "${COLOR_LIGHT_RED}CLUSTER_HOST not found in env! Please set as main domain for app subdomains.${COLOR_NC}\n" && exit 1

  printf "${COLOR_BLUE}installing minikube${COLOR_GREEN}\n"
  sh $root/bin/minikube-install.sh
  [ $? -ne 0 ] && printf "${COLOR_LIGHT_RED}Something went wrong installing minikube${COLOR_NC}\n" && exit 1
  printf "${COLOR_NC}"

  printf "${COLOR_BLUE}installing Letsencrypt Staging CA${COLOR_GREEN}\n"
  sh $root/bin/add-trusted-ca-to-docker-domains.sh
  [ $? -ne 0 ] && printf "${COLOR_LIGHT_RED}Something went wrong installing certificates${COLOR_NC}\n" && exit 1
  printf "${COLOR_NC}"
fi

printf "${COLOR_BLUE}deploying all charts\n${COLOR_GREEN}"
helm template -r mostack $root | kubectl apply -f -
[ $? -ne 0 ] && printf "${COLOR_LIGHT_RED}Something went wrong installing charts${COLOR_NC}\n" && exit 1
printf "${COLOR_NC}"

# wait dependent charts ready, like lego
printf "${COLOR_BLUE}waiting for charts to become available${COLOR_YELLOW}\n"
kubectl rollout status -w deployment/mostack-kube-lego
printf "${COLOR_NC}"

printf "${COLOR_BLUE}starting tunnels${COLOR_NC}\n"
# and run tunnel to minikube node's port 80 and 443
[ ! -z $isMini ]  && sh $root/bin/tunnel-to-minikube-ingress.sh

printf "${COLOR_WHITE}ALL DONE!${COLOR_NC}\n"
