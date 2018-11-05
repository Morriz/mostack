apiVersion: helm.integrations.flux.weave.works/v1alpha2
kind: FluxHelmRelease
metadata:
  name: docker-registry
  namespace: system
  annotations:
    flux.weave.works/automated: "true"
    flux.weave.works/tag.chart-image: semver:~0.2.2
spec:
  namespace: system
  chartGitPath: docker-registry
  releaseName: docker-registry
  values:
    # Only minikube: using hostNetwork hack until hostPort works with CNI
    # @todo: remove and enable localproxy when ready
    hostNetwork: false # {{ISMINIKUBE}}
    localproxy:
      enabled: false # {{NOTISMINIKUBE}}
    ingress:
      enabled: true
      tls: true
      hostname: reg.{{CLUSTER_HOST}}
    persistentVolume:
      existingClaim: slow-pvc
