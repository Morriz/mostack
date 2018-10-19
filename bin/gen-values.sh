#!/usr/bin/env bash
root=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )
. $root/bin/colors.sh
. $root/.env.sh

# uses 'mo'
which mo > /dev/null
if [ $? -ne 0 ]; then
  echo "'mo' needs to be installed:"
  echo "curl https://raw.githubusercontent.com/tests-always-included/mo/master/mo -o mo&& chmod u+x mo && mv mo /usr/local/bin)"
  exit 1
fi

parseFiles() {
  provider=$1
  cat $root/templates/service-index.html | mo > $root/docgen/${provider}-service-index.html
  shift
  for f in "$@"; do
    echo generating values/_gen/$provider/$f
    cat "$f" | mo > $root/values/_gen/$provider/$f
  done
}

printf "${COLOR_WHITE}GENERATING VALUES:${COLOR_NC}\n"

rm -rf $root/values/_gen/*
mkdir $root/values/_gen/local
mkdir $root/values/_gen/gce
cd $root/values > /dev/null
baseFiles=$(find . -name "*.yaml" -maxdepth 1 | cut -c 3-)
cd gce
gceFiles=$(find . -name "*.yaml" -maxdepth 1 | cut -c 3-)
cd -

. $root/secrets/local.sh
parseFiles local $baseFiles
cat $root/templates/README.md | mo > $root/README.md

. $root/secrets/gce.sh
parseFiles gce $baseFiles
parseFiles gce $gceFiles
cat $root/README.md | mo > $root/docgen/README-gce.md

cd $root > /dev/null
