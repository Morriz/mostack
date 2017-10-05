#!/usr/bin/env bash
# this script will start all components, or the folder given as argument, in the right order
folder=$1
root=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )
k8s=$root/k8s
folders='api cluster drone registry'
foldersArray=($folders)

. $root/bin/colors.sh

if [ $# -eq 0 ]; then
  printf "applying everything for folders: ${COLOR_WHITE}$folders${COLOR_NC}\n"
  echo "------------------------------------------------------------------------"
  k apply -f ${root}k8s/istio/istio-auth.yaml
  k apply -f ${root}k8s/istio/addons/
else
  foldersArray=($folder)
fi

for f in "${foldersArray[@]}"
do

  dir="$k8s/$f"

  coloredFolder="${COLOR_WHITE}$f${COLOR_NC}"
  printf "applying folder: $coloredFolder\n"

  if [ -f $dir/install.sh ]; then
    printf "> custom install for folder: $coloredFolder\n"
    . $dir/install.sh
  else

    echo "- creating secrets"
    printf "${COLOR_GREEN}"
    find $dir -type f -iname '*-secret.yaml' -exec kubectl apply -f {} \;
    printf "${COLOR_NC}"

    echo "- creating RBAC stuff"
    printf "${COLOR_GREEN}"
    find $dir -type f -iname '*-rbac*.yaml' -exec kubectl apply -f {} \;
    printf "${COLOR_NC}"

    echo "- creating configmaps"
    printf "${COLOR_GREEN}"
    find $dir -type f -iname '*-cm.yaml' -exec kubectl apply -f {} \;
    printf "${COLOR_NC}"

    echo "- creating everything else"
    printf "${COLOR_GREEN}"
    find $dir -type f \( -iname '*.yaml' ! -iname '*-secret.yaml' ! -iname '*-rbac*.yaml' ! -iname '*-cm.yaml' \) -exec kubectl apply -f {} \;
    printf "${COLOR_NC}"
  fi

done
echo "DONE!"

