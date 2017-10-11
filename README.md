# Mo'z cluster reference stack
## (To automate all da things in 2018)

Using the following (mostly open source) technologies:
* [Kubernetes](https://github.com/kubernetes/kubernetes) for container orchestration
* [Kops](https://github.com/kubernetes/kops) for installing Kubernetes (anywhere you want) on [CoreOS](https//coreos.com) nodes
* Or [Minikube](https://github.com/kubernetes/minikube) for running a local k8s cluster

Running the following Kubernetes applications/tools:
* [Istio](https://github.com/istio/istio) for service mesh security, insights and other enhancements
* *COMING SOON:* [ExternalDNS](https://github.com/kubernetes-incubator/external-dns) for making our services accesible at our FQDN
* Docker Registry for storing locally built images, and as a proxy + storage for external ones.
* [Drone](https://github.com/drone/drone) for Ci/CD, using these plugins:
    * [drone-docker](https://github.com/drone-plugins/drone-docker) for pushing new image
    * [drone-kubernetes](https://github.com/honestbee/drone-kubernetes) to deploy
    *

## 1. Install
### 1.1 Install your kubernetes cluster

Please read up on booting your cluster with [Kops] or minikube.

Make sure you boot the cluster with a main nginx ingress controller. Minikube does this by default.

### 1.2 Configure your cluster

While you're waiting you can

    cp values.sample.yaml values.yaml

And start editing values.yaml

IMPORTANT: The subdomains must all point to the main public nginx controller, which will serve all our public ingresses.

### 1.3 Install everything

PREREQUISITES:
- helm (if on osx it will detect and autoinstall)
- forked [Morriz/nodejs-demo-api](https://github.com/Morriz/nodejs-demo-api)
- [letsencrypt staging ca](https://letsencrypt.org/certs/fakelerootx1.pem) (click and add to your cert manager)
- In case you run minikube or another local cluster behind nat/firewall, make sure that port 80 and 443 are portforwarded to your local machine

Running the main installer with:

    bin/install.sh
will install everything. Please edit `bin/install.sh` to comment out the minikube installer if needed
If on minikube, the script will also set up port forwarding to the lego node, and an ssh tunnel for the incoming traffic on your laptop

## 2. Apps

Please check if all apps are running:

    kubectl get all --all-namespaces

and wait...then test the following web apps:

## 2.1 Drone CI/CD

### 2.1.1 Configure Drone

1. Go to your public drone url (https://drone.dev.yourdoma.in) and select the repo `nodejs-demo-api`.
2. Go to the 'Secrets' menu and create the following:
KUBERNETES_CERT=
KUBERNETES_TOKEN=
KUBERNETES_DNS=10.0.0.10 # or custom
REGISTRY=localhost:5000 # or public

For getting the right cert and token please read last paragraph here: https://github.com/honestbee/drone-kubernetes

## 2.1.2 Trigger pipeline

1. Commit to repo of choice and trigger build in our Drone.
2. Drone builds and does tests
3. Drone pushes docker image artifact to our private docker registry
4. Drone updates our running k8s deployment to use the new version
5. Kubernetes detects config change and does an automated rolling update/rollback.

### 2.2 API

Check output for the following url: https://api.dev.yourdoma.in/api/publicmethod
