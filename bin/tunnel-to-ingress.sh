#!/usr/bin/env bash
minikube_ip=$(minikube ip)
local_ip=127.0.0.1

sudo killall ssh >/dev/null 2>&1

minikube tunnel --cleanup &>/dev/null 2>&1

# port forward incoming 80,443 to nginx portforward that we created in dashboards.sh
sudo ssh -N -p 22 -g $USER@$local_ip -L $local_ip:443:$minikube_ip:443 -L $local_ip:80:$minikube_ip:80 &
