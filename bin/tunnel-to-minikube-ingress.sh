#!/usr/bin/env bash
cluster_ip=$(minikube ip) # or another ip when not using minikube
local_ip=$(ifconfig | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p' | sed -n '1 p')
#echo "local_ip: $local_ip"
#echo "cluster_ip: $cluster_ip"

# the next line should suffice once we have lego receiving incoming correctly
#sudo ssh -N -p 22 -g $USER@$local_ip -L $local_ip:80:$cluster_ip:80 -L $local_ip:443:$cluster_ip:443 &

# port forward to lego for now, until we fix throughput
killall kubectl &> /dev/null
kubectl -n system port-forward $(kubectl -n system get po -l app=kube-lego -o jsonpath='{.items[0].metadata.name}') 8080:8080 &

# for now we directly forward localhost:80 to lego's pod, since we don't have acme verification throughput yet
sudo killall ssh &> /dev/null
sudo ssh -N -p 22 -g $USER@$local_ip -L $local_ip:80:127.0.0.1:8080 -L $local_ip:443:$cluster_ip:443 &
echo ""
