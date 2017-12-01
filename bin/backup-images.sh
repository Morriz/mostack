#!/usr/bin/env bash

root=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )

eval $(minikube docker-env);

destination=$root/minidata/images

if ! type "pv" > /dev/null; then
	echo 'pv' command not found on your system, install it to get a nice progress indicator...
	exit 1
fi

# only backup images with dots in them (long file names)
images=$(docker images | tail -n +2 | awk '{print $1}' | grep -F '.')
for image in $images; do
  fileName="${image//\//__}.tgz"
  if [[ -s $destination/$fileName ]]; then
    echo "backup file $fileName already exists with filesize > 0, skipping backup..."
    continue
  fi
  echo "backing up $image to $fileName"
  docker save $image | pv | gzip -c > $destination/$fileName
done
