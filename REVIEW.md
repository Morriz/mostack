# Review regarding different local cluster boot scenarios.

I have tried the following setups extensively while trying to find a bulletproof approach to launch a (preferably multinode) kubernetes cluster to deploy mostack on.

So far I favor nr 2 because of boot times and resource usage, even tho it has some limitations.

## 1. Minikube

Pros:

* Great out of the box setup.

Cons:

* Not a real multinode cluster.
* kubeadm support is poor.

## 2. kubeadm-dind-cluster

Pros:

* Boots really fast.

Cons:

* Registry proxy doesn't seem to work, so no `localhost:5000` repo possible. Which means using valid domain and access over https. I only see this possible using letsencrypt prod certs, because for the staging certs we would need to patch the docker host's CA to accept them. (The other setups do that.)
* Can't modify the host docker because that is a container itself. So no possibility to inject DOCKER_EXTRA_ARGS or stuff like adding to CA for letsencrypt staging.
* Containers are found under `/dind/docker/containers`, as opposed to regular `/var/lib/docker/containers`. So minor modification necessary to scrape logs.

## 3. Vagrant multi-node setups

### 3.1 Kubespray setup

Pros:

* Multinode as well.
* Highly configurable, because Ansible.
* Robust, because Ansible.
* Repeatable for other environments.

Cons:

* superrrrrslowwww


### 3.1 Custom

Pros:

* Multinode as well
* No ansible, so simpler with just kubeadm

Cons:

* slow, but not as slow as Kubespray
