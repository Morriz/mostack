#!/usr/bin/env bash
root=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )
. $root/bin/colors.sh
shopt -s expand_aliases
. $root/bin/aliases
. $root/secrets/minikube.sh

cluster_ip=$(minikube ip) # or another ip when not using minikube
local_ip=127.0.0.1 # $(ifconfig | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p' | sed -n '1 p')

sudo killall ssh > /dev/null 2>&1

# port forward incoming 80,443 to our cluster
sudo ssh -N -p 22 -g $USER@$local_ip -L $local_ip:443:$cluster_ip:443 &
sudo ssh -N -p 22 -g $USER@$local_ip -L $local_ip:80:$cluster_ip:80 &
