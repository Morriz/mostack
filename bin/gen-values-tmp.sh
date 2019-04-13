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
  mkdir $root/$type.tmp
  [ "$type" = "values" ] && touch $root/$type.tmp/all.yaml
  for f in "$@"; do
    ns=$(dirname $f)
    app=$(basename $f)
    echo generating $type.tmp/$f
    mkdir -p $root/$type.tmp/$ns
    cat $f | mo >$root/$type.tmp/$f
    if [ "$type" = "values" ]; then
      printf "${app::-5}:\n" >>$root/$type.tmp/all.yaml
      echo "$(cat $root/$type.tmp/$f | sed 's/^/  /')" >>$root/$type.tmp/all.yaml
    fi
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

cat $root/README.md | mo >$root/docgen/README.md
cat $root/tpl/service-index.html | mo >$root/docgen/service-index.html
