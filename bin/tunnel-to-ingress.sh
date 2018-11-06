#!/usr/bin/env bash
root=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )
. $root/bin/colors.sh
shopt -s expand_aliases
. $root/bin/aliases
. $root/secrets/local.sh
. $root/.env.sh

local_ip=127.0.0.1

sudo killall ssh > /dev/null 2>&1

# port forward incoming 80,443 to nginx portforward that we created in dashboards.sh
sudo ssh -N -p 22 -g $USER@$local_ip -L $local_ip:443:$local_ip:32443 -L $local_ip:80:$local_ip:32080 &
