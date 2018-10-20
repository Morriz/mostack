#!/usr/bin/env bash
export NUM_NODES=2
export CNI_PLUGIN=calico-kdd
export ENABLE_CEPH=y
export DIND_REGISTRY_MIRROR=http://localhost:6000
# Don't change next two, necessary to open for scraping
export CONTROLLER_MANAGER_address=0.0.0.0
export SCHEDULER_address=0.0.0.0
export CLUSTERTYPE=multinode

# running the cluster will also set the correct kubectl context
dind/dind-cluster-v1.11.sh up
. ./.env.sh
. secrets/local.sh
# . bin/add-trusted-ca-to-docker-domains.sh
 