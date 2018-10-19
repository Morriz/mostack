#!/usr/bin/env sh
root=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )
shopt -s expand_aliases
. ./.env.sh

if [ "$CLUSTERTYPE" == "minikube" ]; then
	eval $(minikube docker-env);
else
	eval "$(docker-machine env kube-node-1)"
fi	

location=$root/minidata/images

filenames=$(ls $location/*.tgz)
images=$(docker images | tail -n +2 | awk '{print $1}' | grep -F '.')

if ! type "pv" > /dev/null; then
	echo 'pv' command not found on your system, install it to get a nice progress indicator...
	exit 1
fi

containsElement () {
  local e match="$1"
  shift
  for e; do [[ "$e" == "$match" ]] && return 0; done
  return 1
}

for filename in $filenames
do
	strippedFilename=$(basename $filename .tgz)
	image=${strippedFilename//__/\/}
	containsElement $image $images
	if [ $? == 0 ]; then
	 echo "$image already exists, skipping..."
	 continue
	fi
  echo "restoring $image"
	gzip -d -c $filename | pv | docker load
done
