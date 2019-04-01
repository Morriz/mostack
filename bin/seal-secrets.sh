#!/usr/bin/env bash#!/usr/bin/env bash
root=$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd .. && pwd)
. bin/colors.sh
. ./.env.sh
provider=${1:-'gce'}
. secrets/${provider}.sh

kubeseal --fetch-cert \
  --controller-namespace=adm \
  --controller-name=sealed-secrets \
  >pub-cert.pem

parseFiles() {
  type=$1
  shift
  for f in "$@"; do
    ns=$(dirname $f)
    package=$(basename $f | rev | cut -c 6- | rev)
    echo sealing $type/$f
    cat $f | mo >$ns/$type.yaml
    kubectl -n $ns create secret generic ${package}-$type --from-file=$ns/$type.yaml --dry-run -o yaml | kubeseal --format=yaml --cert=$root/pub-cert.pem - >$root/releases/$ns/${package}-$type.yaml
    rm $ns/$type.yaml
  done
}

printf "${COLOR_WHITE}SEALING SECRETS:${COLOR_NC}\n"

cd values >/dev/null
files=$(find . -name "*.yaml" -maxdepth 2 | cut -c 3-)
parseFiles values $files
cd ../secrets >/dev/null
files=$(find . -name "*.yaml" -maxdepth 2 | cut -c 3-)
parseFiles secrets $files
cd .. >/dev/null

cat $root/README.md | mo >$root/docgen/README.md
cat $root/templates/service-index.html | mo >$root/docgen/service-index.html
