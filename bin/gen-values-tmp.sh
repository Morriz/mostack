#!/usr/bin/env bash

# Only needed when deploying helm chart sdirectly to cluster !!

root=$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd .. && pwd)
. $root/bin/colors.sh
. ./.env.sh
provider=${1:-'local'}
. $root/secrets/${provider}.sh

rm -rf $root/values/_tmp >/dev/null 2>&1
mkdir $root/values/_tmp >/dev/null

parseFiles() {
  for f in "$@"; do
    ns=$(dirname $f)
    echo generating values.tmp/$f
    mkdir _tmp/$ns >/dev/null 2>&1
    cat $f | mo >_tmp/$f
  done
}

printf "${COLOR_WHITE}GENERATING TMP VALUE FILES:${COLOR_NC}\n"

cd $root/values >/dev/null
baseFiles=$(find . -name "*.yaml" -maxdepth 2 | cut -c 3-)
parseFiles $baseFiles
cd - >/dev/null
rm -rf values.tmp
mv $root/values/_tmp $root/values.tmp
