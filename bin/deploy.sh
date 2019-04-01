#!/usr/bin/env bash

helm repo add weaveworks https://weaveworks.github.io/flux
helm repo update
helm --namespace=system upgrade --install --force flux \
    --tls --tls-verify \
    --tls-ca-cert ./tls/ca.pem \
    --tls-cert ./tls/flux-helm-operator.pem \
    --tls-key ././tls/flux-helm-operator-key.pem \
    --tls-hostname tiller-deploy.kube-system \
    --set rbac.create=true \
    --set helmOperator.create=true \
    --set helmOperator.tls.enable=true \
    --set helmOperator.tls.verify=true \
    --set helmOperator.tls.secretName=helm-client \
    --set helmOperator.tls.caContent="$(cat ./tls/ca.pem)" \
    --set git.url=git@github.com:Morriz/mostack \
    --set git.branch=${GIT_BRANCH:-master} \
    --set git.path=releases \
    --set git.ciSkip=true \
    --set git.pollInterval=15s \
    weaveworks/flux

export FLUX_POD=$(kubectl get pods --namespace system -l "app=flux,release=flux" -o jsonpath="{.items[0].metadata.name}")
kubectl -n system rollout status deployment/flux-helm-operator
echo ""
echo "Now add the following public key in your repo's settings as deploy key:"
kubectl -n system logs $FLUX_POD | grep identity.pub | cut -d '"' -f2
cat <<"EOF"
If all is well the repo will become accessible, the deployment will slowly unfold, and we have to wait for the sealed-secrets pod to come up.
Run a watch with:

watch -n1 -x kubectl --all-namespaces=true get po,deploy

In the mean time make sure you have kubeseal. On OSX:

wget https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.7.0/kubeseal-darwin-amd64
sudo install -m 755 kubeseal-darwin-amd64 /usr/local/bin/kubeseal

When the pod/sealed-secrets-* in namespace adm is ready, we can seal our secrets with:

sh bin/seal-secrets.sh

Finally commit the changes in this repo and let The HelmRelease operator do it's work.

To prepare for disaster recovery you should backup the sealed-secrets controller private key with:

kubectl get secret -n adm sealed-secrets-key -o yaml --export > sealed-secrets-key.yaml
To restore from backup after a disaster, replace the newly-created secret and restart the controller:

kubectl replace secret -n adm sealed-secrets-key -f sealed-secrets-key.yaml
kubectl delete pod -n adm -l app=sealed-secrets
EOF
