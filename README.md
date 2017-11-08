# Mo'z Kubernetes reference stack
## (To automate all da things in 2018)

Using Kubernetes because...reasons (go Google).

In my opinion we always want a single store of truth (Git) that houses all we do as code.
So I set out to create a stack that declares our entire application, allowing to idempotently apply any changes.
I'd like to avoid imperatively wiring parts together or operating on parts alone.
Therefor I would like the result to be a git repo allowing us to transform every git push into the next app state.

So far I am using the following (mostly open source) technologies:
* [Kubernetes](https://github.com/Kubernetes/Kubernetes) for describing our container infrastructure.
* [Kops](https://github.com/Kubernetes/kops) for installing Kubernetes (anywhere you want) on [CoreOS linux](https//coreos.com) nodes
* Or [Minikube](https://github.com/Kubernetes/minikube) for running a local k8s cluster
* [Helm](https://github.com/Kubernetes/helm) for packaging and deploying of Kubernetes apps and subapps.

Running the following Kubernetes applications/tools:
* *DISABLED FOR NOW:* [Istio](https://github.com/istio/istio) for service mesh security, insights and other enhancements
* *COMING SOON:* [ExternalDNS](https://github.com/Kubernetes-incubator/external-dns) for making our services accesible at our FQDN
* Docker Registry for storing locally built images, and as a proxy + storage for external ones.
* [Prometheus Operator](https://github.com/coreos/prometheus-operator) + [Prometheus](https://prometheus.io) + [Grafana](https://grafana.com)
* [ElasticSearch](www.elastic.co) + [Kibana](www.elastic.co/products/kibana) for log indexing & viewing
* [Drone](https://github.com/drone/drone) for Ci/CD, using these plugins:
    * [drone-docker](https://github.com/drone-plugins/drone-docker) for pushing new image
    * [drone-Kubernetes](https://github.com/honestbee/drone-Kubernetes) to deploy
    *

We will be going through the following workflow:

1. Configuration
2. Deploying the stack
3. Testing the apps
4. Destroying the cluster

At any point can any step be re-run to result in the same (idempotent) state.
After destroying the cluster, and then running install again, all storage endpoints will still contain the previously built/cached artifacts and configuration.
The next boot should thus be much faster :)

PREREQUISITES:
- A running Kubernetes cluster with RBAC enabled and `kubectl` installed on your local machine.
- Helm ^2.7.0 (this version depends on `template` functionality, if on osx it will detect and autoinstall)
- Forked [Morriz/nodejs-demo-api](https://github.com/Morriz/nodejs-demo-api)
- [Letsencrypt staging CA](https://letsencrypt.org/certs/fakelerootx1.pem) (click and add to your cert manager temporarily if you like to bypass browser https warnings)
- In case you run minikube or another local cluster behind nat/firewall, make sure that port 80 and 443 are portforwarded to your local machine

On OSX the `bin/install.sh` script will also start a minikube cluster (if it has not started yet).
If you wish to also deploy to GKE (Google Container Engine), please create a cluster there:

    gloud container cluster create mocluster

#### 1 Configure the apps

    cp values/drone.sample.yaml values/drone.yaml

And edit values/*.yaml (see all the options in `charts/*/values.yaml`).

Also `export CLUSTER_HOST=...` with whatever cluster domain you want to point to.

IMPORTANT: The `CLUSTER_HOST` subdomains must all point to the main public nginx controller, which will serve all our public ingresses.

Also create a Drone app key+secret in GitHub/BitBucket so that drone can operate on your forked `Morriz/nodejs-api-demo` repo.
Fill in those secrets in the `drone.yaml` values.

EXCEPTIONAL: The ElasticSearch + Kibana configuration is not yet *helmified* and needs to be edited here:
`k8s/elk` (specifically the service url is to be found here: `k8s/elk/elk-ing.yaml`)

If you also want to deploy to your gke cluster, also edit these values: `values/test-gce/*.yaml`.

#### 2 Deploy the stack

Running the main installer with

    bin/install.sh

will do a `kubectl use-context minikube` and install the stack with the values from `values/*.yaml`.

Running the main installer with

    bin/install.sh test-gce

will do a `kubectl use-context $KUBE_CONTEXT` and install the stack with the values from `values/test-gce/*.yaml`.

If on minikube, the script will also set up port forwarding to the lego node, and an ssh tunnel for the incoming traffic on your local machine.

### 3. Testing the apps

Please check if all apps are running:

    kubectl get all --all-namespaces

and wait...

The `api` deployment can't start because it can't find it's local docker image, which is not yet in the registry.
Drone needs to build from a commit first, which we will get to later. After that the `api:latest` tag is permanently stored in the registry's file storage,
which survives cluster deletion, and will thus be immediately used upon cluster re-creation.

Let's configure Drone now:

#### 3.1 Drone CI/CD

##### 3.1.1 Configure Drone

1. Go to your public drone url (https://drone.dev.yourdoma.in) and select the repo `nodejs-demo-api`.
2. Go to the 'Secrets' menu and create the following:

        KUBERNETES_CERT=...
        KUBERNETES_TOKEN=...
        KUBERNETES_DNS=10.0.0.10 # if minikube
        REGISTRY=localhost:5000 # or public

For getting the right cert and token please read last paragraph here: https://github.com/honestbee/drone-Kubernetes

##### 3.1.2 Trigger build pipeline

1. Now commit to the forked `Morriz/nodejs-api-demo` repo and trigger a build in our Drone.
2. Drone builds and does tests
3. Drone pushes docker image artifact to our private docker registry
4. Drone updates our running k8s deployment to use the new version
5. Kubernetes detects config change and does an automated rolling update/rollback.

#### 3.2 API

Check output for the following url: https://api.dev.yourdoma.in/api/publicmethod

It should already be running ok, or it is in the process of detecting the new image and rolling out the update.

#### 3.3 Prometheus stats in Grafana

Look at a pre-installed [Grafana dashboard](https://grafana.dev.yourdoma.in) showing the system cluster metrics.
Use the following default creds if not changed already in `values/grafana.yaml`:

* username: admin
* password: jaja

To see the prometheus and alertmanager instances for the `system` operators go to:
https://prometheus.dev.yourdoma.in/
https://alertmanager.dev.yourdoma.in/

To see the prometheus and alertmanager instances for `team-frontend` go to:
https://prom-frontend.dev.yourdoma.in/
https://alerts-frontend.dev.yourdoma.in/

#### 3.4 Kibana log view

Look at a pre-installed [Kibana dashboard with Logtrail](https://kibana.dev.yourdoma.in/app/logtrail) showing the cluster logs.

### 4. Deleting the cluster

On OSX you can delete the entire minikube cluster with

    bin/minikube-delete.sh

On gcloud:

    gloud container cluster delete mocluster
