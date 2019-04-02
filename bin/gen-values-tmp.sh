#!/usr/bin/env bash

# Only needed when deploying helm chart sdirectly to cluster !!

root=$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd .. && pwd)
. $root/bin/colors.sh
. ./.env.sh
provider=${1:-'local'}
. $root/secrets/${provider}.sh

parseFiles() {
  type=$1
  shift
  rm -rf $root/$type.tmp >/dev/null 2>&1
  rm -rf /tmp/$type >/dev/null 2>&1
  for f in "$@"; do
    ns=$(dirname $f)
    echo generating $type.tmp/$f
    mkdir -p /tmp/$type/$ns
    cat $f | mo >/tmp/$type/$f
  done
}

printf "${COLOR_WHITE}GENERATING TMP VALUE FILES:${COLOR_NC}\n"

cd values >/dev/null
files=$(find . -name "*.yaml" -maxdepth 2 | cut -c 3-)
parseFiles values $files
cd ../secrets >/dev/null
files=$(find . -name "*.yaml" -maxdepth 2 | cut -c 3-)
parseFiles secrets $files
cd .. >/dev/null

mv /tmp/values $root/values.tmp
mv /tmp/secrets $root/secrets.tmp
