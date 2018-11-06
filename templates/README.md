# Mo'z Kubernetes reference stack
## (To automate all da things in 2018)

Using Kubernetes because...reasons (go [Google](https://www.google.com/search?q=kubernetes)).

In my opinion we always want a single store of truth (Git) that houses all we do as code.
So I set out to create a stack that declares our entire kubernetes platform, allowing to idempotently apply changes towards our desired end state without side effects.

So far I am using the following (mostly open source) technologies:

To boot up a cluster (see `bin/install*.sh` scripts) you can choose one of the following setups before running the package installer:

* [Minikube](https://github.com/Kubernetes/minikube) for running a local k8s cluster.
* [kubeadm-cluster-dind](https://github.com/kubernetes-sigs/kubeadm-dind-cluster) for running a local multinode k8s cluster as an alternative that is more close to the real deal. My favorite, as it is fast.
* [Vagrant](https://www.vagrantup.com) for running a local multinode cluster that even more closely mimics a currently available cloud cluster.
  
To boot the following Kubernetes applications/tools:

* [Kubernetes](https://github.com/Kubernetes/Kubernetes) for describing our container infrastructure.
* [Helm](https://github.com/Kubernetes/helm) for packaging and deploying of Kubernetes apps and subapps.
* Docker Registry for storing locally built images, and as a proxy + cache for external ones.
* [Prometheus Operator](https://github.com/coreos/prometheus-operator) + [Prometheus](https://prometheus.io) + [Grafana](https://grafana.com) for monitoring.
* [Calico](https://github.com/projectcalico) for networking and policies k8s style.
* [Cert Manager](https://github.com/jetstack/cert-manager) for automatic https certificate creation for public endpoints.
* [ElasticSearch](www.elastic.co) + [Kibana](www.elastic.co/products/kibana) for log indexing & viewing.
* [Drone](https://github.com/drone/drone) for building, testing and and pushing images to our private registry.
* [Weave Flux operator]() implementing [GitOps](https://www.weave.works/technologies/gitops/) automated deployment workflow, listening to newly pushed images.
* [Weave Scope](https://www.weave.works/oss/scope/) for a graphic overview of the network topology and services.

Wishlist for the next version:
* Better Secret handling either with Sealed Secrets or Vault
* [Istio](https://github.com/istio/istio) for service mesh security, traceability and other enhancements.
* [Ambassador](https://www.getambassador.io): the new kubernetes native api gateway.

Alright, let's get to it. Follow me please!
We will be going through the following workflow:

1. Configuration
2. Deploying the stack
3. Testing the apps
4. Destroying the cluster

At any point can any step be re-run to result in the same (idempotent) state.
After destroying the cluster, and then running install again, all storage endpoints will still contain the previously built/cached artifacts and configuration. The next boot should thus be faster.

## PREREQUISITES:

* A running Kubernetes 1.11+ cluster with RBAC enabled, Calico 3.2+ CNI plugin, and `kubectl` installed on your local machine:
	* On OSX you may install one of 3 types of clusters:
        * `bin/install-minikube.sh` will start a single node. minikube cluster for you, and try to restore docker images.
        * `bin/install-dind.sh` will start a multi node dind cluster. Slower initial startup than miinikube, but much faster on 'up'. My preferred setup.
        * `bin/install-vagrant.sh` will start a multi node vagrant cluster.
	* If you wish to deploy to GCE (Google Compute Engine), please create a cluster there:

		    bin/gce-create.sh

* [Helm](https://helm.sh) (`brew install helm`?)
* Forked [Morriz/nodejs-demo-api](https://github.com/Morriz/nodejs-demo-api)
* [Letsencrypt staging CA](https://letsencrypt.org/certs/fakelerootx1.pem) (click and add to your browser's cert manager temporarily if you'd like to bypass browser warnings about https)
* ssh passwordless sudo access. On OSX I have to add my key like this: `ssh-add -K ~/.ssh/id_rsa`.
* For `cert-manager` to work (it autogenerates letsencrypt certs), make sure port 80 and 443 are forwarded to your local machine:
	* by manipulating your firewall
	* or by tunneling a domain from [ngrok](https://ngrok.io) (and using that as `$CLUSTER_HOST` in the config below):
	    * free account: only http works (set `TLS_ENABLE=false` in `secrets/local.sh`) since we can't load multiple tunnels (80 & 443) for one domain
	    * biz account: see provided `templates/ngrok.yaml`
* Create an oAuth app for our Drone and copy the key & secret in [GitHub](https://github.com/settings/developers) so that drone can operate on your forked `Morriz/nodejs-api-demo` repo. Fill in those secrets in the `drone.yaml` values below.

## 1. Configuration

Copy `secrets/sample.sh` to `secrets/local.sh` (and `secrets/gce.sh` for deploying to gce), and edit them.
If needed you can also edit `values/*.yaml` (see all the options in `charts/*/values.yaml`), but for a first boot I would leave them as is.

IMPORTANT: The `$CLUSTER_HOST` subdomains must all point to your laptop ip (I use ngrok for that, see `bin/ngrok.sh`). Then the `bin/tunnel-to-ingress.sh` script can forward incoming port 443 and 80 to the nginx controller, which will serve all our public ingresses.

Now you may generate the final value files (and docs with live) links into `values/_gen` by running:

    . bin/gen-values.sh

This step will always execute in the package installer, so no need to do it before a `bin/install-packages.sh`.
And, as you might have noticed, this README got overwritten so links are pointing to your CLUSTER_HOST domain for working clickable links :)

To load the env vars, aliases and functions (used throughout the stack) source them in your shell:

    . ./.env.sh
    . bin/aliases

## 2. Deployment

A dirty bash script boots everything in the right order. Could use more fancy stuff like Ansible (check out Kubespray), but I will leave that to you.
Running the main installer with

    bin/install-packages.sh

will install a lot of necessary `k8s/*` manifests and the helm charts with the values from `values/_gen/*.yaml`.

That's it. You can run this every time you make a change and it will idempotently apply the desired state.

## 3. Testing the apps

Please check if all apps are running:

    kaa

and wait...

The `api` deployment can't start because it can't find it's local docker image, which is not yet in the registry.
Drone needs to build from a commit first, which we will get to later. After that the `api:latest` tag is permanently stored in the registry's file storage, which survives cluster deletion, and will thus be immediately used upon cluster re-creation.

When all deployments are ready the local service proxies are automatically started with:

    bin/dashboards.js

and [the service index](./docgen/local-service-index.html) will open.

### 3.1 Drone CI/CD

### 3.1.1 Configure Drone

1. Go to your public drone url (https://drone.{{CLUSTER_HOST}}) and select the repo `nodejs-demo-api`.
2. Go to the 'Secrets' menu and create the following entries (follow the comments to get the values):

        kubernetes_cert= # ktf get secret $(ktf get sa drone-deploy -o jsonpath='{.secrets[].name}{"\n"}') -o jsonpath="{.data['ca\.crt']}"
        kubernetes_token= # ktf get secret $(ktf get sa drone-deploy -o jsonpath='{.secrets[].name}{"\n"}') -o jsonpath="{.data.token}" | base64 -d
        kubernetes_dns= # ksk get po --selector=k8s-app=kube-dns --output=jsonpath={.items..status.hostIP}
        registry=localhost:5000 # or the public version if you made the registry accessible as a service

### 3.1.2 Trigger the build pipeline

1. Now commit to the forked `Morriz/nodejs-api-demo` repo and trigger a build in our Drone.
2. Drone builds and does tests, pushes docker image artifact to our private docker registry.
3. Weave Flux sees the image, updates the deployment, and commits the updated config to git.

### 3.2 API

* https://api.{{CLUSTER_HOST}}/api/publicmethod
* https://api-stg.{{CLUSTER_HOST}}/api/publicmethod
* https://api.{{CLUSTER_HOST}}/api/publicmethod

It should already be running ok, or it is in the process of detecting the new image and rolling out the update.

### 3.3 Prometheus monitoring

#### 3.3.1 Grafana

Look at a pre-installed [Grafana dashboard](https://grafana.{{CLUSTER_HOST}}) showing the system cluster metrics.
Use the following default creds if not changed already in `values/grafana.yaml`:

* username: admin
* password: jaja

#### 3.3.2 Prometheus

Look at the Prometheus view to see all targets are scrapable. Drone should not be able to be scraped and prometheus alerts will be sent to the alertmanager. (Chek next section now and come back.)

We need to tell Prometheus to use an auth token for scraping: go to [Drone](https://drone.{{CLUSTER_HOST}}) and retrieve the token from the menu.
Copy and paste that into the `secrets/minikube.sh` file `DRONE_AUTH_TOKEN` var.
run the following to create the secret and reload the relevant pods:

    bin/gen-values.sh
    k apply -f values/_gen/$CLUSTER_PROVIDER/secrets.yaml
    km delete pod/prometheus-prometheus-0

You should soon see scrape endpoint `drone-drone` reporting up.    

#### 3.3.3 Alertmanager

The alertmanager view will show the alerts concerning the unreachable endpoints.

### 3.4 Kibana log view

Look at a pre-installed [Kibana dashboard with Logtrail](https://logging.{{CLUSTER_HOST}}/app/logtrail) showing the cluster logs.

Creds: Same as Grafana.

### 3.5 Calico

Now that we have all ups running and functional, we can start deploying network policies. Let's start with denying all inbound/outbound ingress and egress for all namespaces:

	k apply -f k8s/policies/deny-all.yaml

Now we can revisit the apps and see most of them failing. Interesting observation on minikube: the main nginx-ingress is still functional. This is because current setup does not operate on the host network. To also control host networking we have to fix some things, but that will arrive in the next update of this stack (hopefully).

Let's apply all the policies needed for every namespace to open up the needed connectivity, and watch the apps work again:

	for ns in default kube-system system monitoring logging team-frontend; do k apply -n $ns -f k8s/policies/each-namespace/defaults.yaml; done
    k apply -f k8s/policies

Sometimes during development stuff is not accessible (yet), so you can delete all the policies to allow full access again:

    for ns in default kube-system system monitoring logging team-frontend; do k -n $ns delete networkpolicy --all; done

### 4. Deleting the cluster

With minikube the preferred way to delete the entire minikube is with the following command:

    mkd

which will backup all the images locally for less bandwidth usage during startup next time.

On GCE:

    bin/gce-delete.sh
