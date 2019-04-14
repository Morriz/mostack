#!/usr/bin/env bash#!/usr/bin/env bash
root=$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd .. && pwd)
. bin/colors.sh
. ./.env.sh
. secrets/${PROVIDER}.sh

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
    exit
    if [ "$type" = "values" ]; then
      cat $f | mo >/tmp/values.yaml
      kubectl -n $ns create secret generic $package-$type --from-file=/tmp/values.yaml --dry-run -o yaml | kubeseal --format=yaml --cert=$root/pub-cert.pem - >$root/releases/$ns/$package-$type.yaml
      rm /tmp/values.yaml
    else
      cat $f | mo | kubeseal --format=yaml --cert=$root/pub-cert.pem - >$root/releases/$ns/$package-$type.yaml
    fi
  done
}

printf "${COLOR_WHITE}SEALING SECRETS:${COLOR_NC}\n"

if [ -e "$1" ]; then
  type=$(echo $1  | awk -F/ '{print $1}')
  files=$(echo $1 | cut -d'/' -f2-)
  cd $type >/dev/null
  parseFiles $type $files
  cd .. >/dev/null
else
  cd values >/dev/null
  [ -z "$1" ] && files=$(find . -name "*.yaml" -maxdepth 2 | cut -c 3-)
  parseFiles values $files
  cd ../secrets >/dev/null
  [ -z "$1" ] && files=$(find . -name "*.yaml" -maxdepth 2 | cut -c 3-)
  parseFiles secrets $files
  cd .. >/dev/null
fi

cat $root/README.md | mo >$root/docgen/README.md
cat $root/tpl/service-index.html | mo >$root/docgen/service-index.html
