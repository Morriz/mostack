#!/usr/bin/env bash
shopt -s expand_aliases
. bin/aliases
. ./.env.sh

helm repo add weaveworks https://weaveworks.github.io/flux
# helm repo add rook-stable https://charts.rook.io/stable
# helm repo add istio.io https://storage.googleapis.com/istio-prerelease/daily-build/master-latest-daily/charts
# helm repo add jetstack https://charts.jetstack.io
# helm repo add banzaicloud-stable https://kubernetes-charts.banzaicloud.com

helm repo update
hs flux \
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

ks rollout status deployment/flux

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

k get secret -n adm sealed-secrets-key -o yaml --export > sealed-secrets-key.yaml
To restore from backup after a disaster, replace the newly-created secret and restart the controller:

k replace secret -n adm sealed-secrets-key -f sealed-secrets-key.yaml
k delete pod -n adm -l app.kubernetes.io/name=sealed-secrets

EOF

if [ -f sealed-secrets-key.yaml ]; then
    k replace secret -n adm sealed-secrets-key -f sealed-secrets-key.yaml
    k delete pod -n adm -l app.kubernetes.io/name=sealed-secrets
fi
ks delete secret flux-git-deploy
ks create secret generic flux-git-deploy --from-file=identity=tls/server-key.pem
ks delete pod -l app=flux

echo <<"EOF"

FINISHED DEPLOYING!

If not done before then add the following public key in your repo's settings as deploy key:

ks logs deployment/flux | grep identity.pub | cut -d '"' -f2

And restart cert-manager when all deployments have come up to make sure it acquires certs:

ks delete pod -l app=cert-manager

EOF
[ -n "$ISLOCAL" ] && bin/ngrok.sh
