# Mo'z Kubernetes reference stack
## (To automate all da things in 2018)

Using Kubernetes because...reasons (go Google).

In my opinion we always want a single store of truth (Git) that houses all we do as code.
So I set out to create a stack that declares our entire application, allowing to idempotently apply any changes.
I'd like to avoid imperatively wiring parts together or operating on parts alone.
Therefor I would like the result to be a git repo allowing us to transform every git push into the next app state.

So far I am using the following (mostly open source) technologies:
* [Kubernetes](https://github.com/Kubernetes/Kubernetes) for describing our container infrastructure.
* [Kops](https://github.com/Kubernetes/kops) for installing Kubernetes (anywhere you want) on [CoreOS](https//coreos.com) nodes
* Or [Minikube](https://github.com/Kubernetes/minikube) for running a local k8s cluster
* [Helm](https://github.com/Kubernetes/helm) for packaging and deploying of Kubernetes apps and subapps.

Running the following Kubernetes applications/tools:
* *DISABLED FOR NOW:* [Istio](https://github.com/istio/istio) for service mesh security, insights and other enhancements
* *COMING SOON:* [ExternalDNS](https://github.com/Kubernetes-incubator/external-dns) for making our services accesible at our FQDN
* Docker Registry for storing locally built images, and as a proxy + storage for external ones.
* [Prometheus](https://prometheus.io) + [Grafana](https://grafana.com)
* [ElasticSearch](www.elastic.co) + [Kibana](www.elastic.co/products/kibana) for log indexing & viewing
* [Drone](https://github.com/drone/drone) for Ci/CD, using these plugins:
    * [drone-docker](https://github.com/drone-plugins/drone-docker) for pushing new image
    * [drone-Kubernetes](https://github.com/honestbee/drone-Kubernetes) to deploy
    *

We will be going through the following workflow:

1. Installing the cluster
2. Deploying the apps
3. Destroying the cluster

At any point can any step be re-run to result in the same (idempotent) state.
After destroying the cluster, and then running install again, all storage endpoints will still contain the previously built/cached artifacts and configuration.
The next boot should thus be much faster :)

### 1. Installing

#### 1.1 Install a (bare) Kubernetes cluster

The `bin/install.sh` script will start the minikube cluster if it has not started yet. Please read up on 1.2 first for configuration.

Please read up on booting your cluster with [Kops] otherwise.
Make sure you boot the cluster with a main nginx ingress controller. Minikube does this by default.

#### 1.2 Configure the apps

While you're waiting you can

    cp values/drone.sample.yaml values/drone.yaml

And start editing values/*.yaml (see all the options in `charts/*/values.yaml`).

Also `export CLUSTER_HOST=...` with whatever cluster domain you want to point to.

IMPORTANT: The `CLUSTER_HOST` subdomains must all point to the main public nginx controller, which will serve all our public ingresses.

And don't forget to install a webhook in the forked `Morriz/nodejs-api-demo` repo and to fill in those secrets in the `drone.yaml` values.

EXCEPTIONAL: The ElasticSearch + Kibana configuration is not yet *helmified* and needs to be edited here:
`k8s/elk` (specifically the service url is to be found here: `k8s/elk/elk-ing.yaml`)

#### 1.3 Deploy everything

PREREQUISITES:
- A running Kubernetes cluster with RBAC enabled and `kubectl` installed on your local machine.
- Helm ^2.7.0 (this version depends on `template` functionality, if on osx it will detect and autoinstall)
- Forked [Morriz/nodejs-demo-api](https://github.com/Morriz/nodejs-demo-api)
- [Letsencrypt staging CA](https://letsencrypt.org/certs/fakelerootx1.pem) (click and add to your cert manager temporarily if you like to bypass browser https warnings)
- In case you run minikube or another local cluster behind nat/firewall, make sure that port 80 and 443 are portforwarded to your local machine

Running the main installer with `bin/install.sh` will install everything. Please edit that script to enable/disable minikube settings if needed.
If on minikube, the script will also set up port forwarding to the lego node, and an ssh tunnel for the incoming traffic on your local machine.

### 2. Apps

Please check if all apps are running:

    kubectl get all --all-namespaces

and wait...

The `api` deployment can't start because it can't find it's local docker image, which is not yet in the registry.
Drone needs to build from a commit first, which we will get to later. After that the `api:latest` tag is permanently stored in the registry's file storage,
which survives cluster deletion, and will thus be immediately used upon cluster re-creation.

Let's configure Drone now:

#### 2.1 Drone CI/CD

##### 2.1.1 Configure Drone

1. Go to your public drone url (https://drone.dev.yourdoma.in) and select the repo `nodejs-demo-api`.
2. Go to the 'Secrets' menu and create the following:

        KUBERNETES_CERT=...
        KUBERNETES_TOKEN=...
        KUBERNETES_DNS=10.0.0.10 # if minikube
        REGISTRY=localhost:5000 # or public

For getting the right cert and token please read last paragraph here: https://github.com/honestbee/drone-Kubernetes

##### 2.1.2 Trigger build pipeline

1. Now commit to the forked `Morriz/nodejs-api-demo` repo and trigger a build in our Drone.
2. Drone builds and does tests
3. Drone pushes docker image artifact to our private docker registry
4. Drone updates our running k8s deployment to use the new version
5. Kubernetes detects config change and does an automated rolling update/rollback.

#### 2.2 API

Check output for the following url: https://api.dev.yourdoma.in/api/publicmethod

It should already be running ok, or it is in the process of detecting the new image and rolling out the update.

#### 2.3 Prometheus stats in Grafana

Look at a pre-installed [Grafana dashboard](https://grafana.dev.yourdoma.in) showing the cluster metrics.
Use the following default creds if not changed already in `values/grafana.yaml`:

* username: Admin
* password: jaja

#### 2.4 Kibana log view

Look at a pre-installed [Kibana dashboard](https://kibana.dev.yourdoma.in) showing the cluster logs.
Use the following index pattern 'filebeat-*` and select one of the time formats and go to "Discover".
