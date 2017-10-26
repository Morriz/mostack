#!/usr/bin/env bash
root=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )

# rewrite labels in docker for kubernetes and restart

alreadyModified=`minikube ssh "echo 'labels=io.kubernetes.container.hash' | sudo grep -f /lib/systemd/system/docker.service"`
if [ ! "$alreadyModified" ]; then
  minikube ssh "sudo sed -i 's/^ExecStart=\/usr\/bin\/docker daemon.*$/& --log-opt labels=io.kubernetes.container.hash,io.kubernetes.container.name,io.kubernetes.pod.name,io.kubernetes.pod.namespace,io.kubernetes.pod.uid/' /lib/systemd/system/docker.service"
  minikube ssh "sudo systemctl daemon-reload"
  minikube ssh "sudo systemctl restart docker.service"
fi

kubectl apply -f $root/k8s/elk/
