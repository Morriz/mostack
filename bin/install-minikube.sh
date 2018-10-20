#!/usr/bin/env bash
. bin/colors.sh
shopt -s expand_aliases
. bin/aliases
export CLUSTERTYPE=minikube

haveMiniRunning=0
minikube ip >/dev/null 2>&1
[ $? -eq 0 ] && haveMiniRunning=1

if [ $haveMiniRunning -ne 1 ]; then
	#  [ -e $CLUSTER_HOST ] && printf "${COLOR_LIGHT_RED}CLUSTER_HOST not found in env! Please set as main domain for app subdomains.${COLOR_NC}\n" && exit 1

	printf "${COLOR_BLUE}Starting minikube cluster${COLOR_NC}\n"
	minikube -v 5 start --memory 8000 \
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

	[ $? -ne 0 ] && printf "${COLOR_LIGHT_RED}Something went wrong starting minikube cluster${COLOR_NC}\n" && exit 1
	printf "${COLOR_NC}"

	# disabling while we use localhost:5000
	#  printf "${COLOR_BLUE}installing Letsencrypt Staging CA${COLOR_NC}\n"
	#  sh bin/add-trusted-ca-to-docker-domains.sh
	#  [ $? -ne 0 ] && printf "${COLOR_LIGHT_RED}Something went wrong installing Letsencrypt Staging CA${COLOR_NC}\n" && exit 1
	#  printf "${COLOR_NC}"
fi

kubectl config use-context minikube

# remove taint that is not removed by kubeadm because of some race condition:
kubectl taint node minikube node-role.kubernetes.io/master:NoSchedule- >/dev/null 2>&1

printf "\n${COLOR_BLUE}Restoring docker images${COLOR_NC}\n"
eval $(minikube docker-env)
. bin/restore-images.sh

printf "${COLOR_BLUE}Syncing clock${COLOR_NC}\n"
minikube ssh -- sudo ln -sf /usr/share/zoneinfo/Europe/Amsterdam /etc/localtime
minikube ssh -- docker run -i --rm --privileged --pid=host debian nsenter -t 1 -m -u -n -i date -u $(date -u +%m%d%H%M%Y)
