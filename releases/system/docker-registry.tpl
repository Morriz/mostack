apiVersion: flux.weave.works/v1beta1
kind: HelmRelease
metadata:
  name: docker-registry
  namespace: system
  annotations:
    flux.weave.works/automated: "true"
    flux.weave.works/tag.chart-image: semver:~2.6.2
spec:
  releaseName: docker-registry
  chart:
    repository: https://kubernetes-charts.storage.googleapis.com
    name: docker-registry
    version: 1.7.0
  valueFileSecrets:
  - name: docker-registry-secrets
  values: {}
