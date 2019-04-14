. ./.env.sh
. secrets/${PROVIDER}.sh

ns=prod
service=api
# create a deploy token @ your git repo and insert user+pass:
user=$REG_USER
pass=$REG_PASS

k="kubectl -n $ns"
$k create secret docker-registry regcred-$service --docker-server=registry.gitlab.com --docker-email=devops@yourdoma.in \
    --docker-username=$user \
    --docker-password=$pass \
    --dry-run -o yaml >./releases/$ns/${service}-regcred.yaml

echo "Created secret: releases/$ns/${service}-regcred.yaml"
