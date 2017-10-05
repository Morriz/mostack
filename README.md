# Mo'z cluster reference stack
## (To automate all da things in 2018)

Using the following (mostly open source) technologies:
* [Kubernetes](https://github.com/kubernetes/kubernetes) for container orchestration
* [Kops](https://github.com/kubernetes/kops) for installing Kubernetes (anywhere you want) on [CoreOS](https//coreos.com) nodes
* Or [Minikube](https://github.com/kubernetes/minikube) for running a local k8s cluster

Running the following Kubernetes applications/tools:
* [Istio](https://github.com/istio/istio) for service mesh security, insights and other enhancements
* [ExternalDNS](https://github.com/kubernetes-incubator/external-dns) for making our services accesible at our FQDN
* Docker Registry for storing locally built images, and as a proxy + storage for external ones.
* [Drone](https://github.com/drone/drone) for Ci/CD, using these plugins:
    * [drone-docker](https://github.com/drone-plugins/drone-docker) for pushing new image
    * [drone-kubernetes](https://github.com/honestbee/drone-kubernetes) to deploy
    *

## 1. Install
### 1.1 Install your bare kubernetes cluster

Please read up on booting your cluster with [Kops] or minikube.

Make sure you boot the cluster with a main nginx ingress controller:

For kops, see:
#### Minikube prerequisites
### 1.2 Configure your cluster

When you have a running cluster you can set your public cluster host in main-config.yaml.
This domain must point to the main public nginx controller, which will serve all our public ingresses.

### Local development: Portforward port 80 and 443

In case you run minikube or another local cluster behind nat/firewall, make sure that:
- port 80 and 443 are portforwarded to your local machine
- both those ports are tunneled to your cluster's master nginx controller

By executing:

    cluster_ip=$(minikube ip) # or another ip when not using minikube
    local_ip=$(ifconfig | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p' | sed -n '1 p')
    sudo ssh -N -p 22 -g $USER@$local_ip -L $local_ip:80:$cluster_ip:80 -L $local_ip:443:$cluster_ip:443 &

## CI/CD Steps

1. Commit to repo of choice and trigger build in our Drone.
2. Drone builds and does tests
3. Drone pushes docker image artifact to our private docker registry
4. Drone updates our running k8s deployment to use the new version
5. Kubernetes detects config change and does an automated rolling update/rollback.
