apiVersion: flux.weave.works/v1beta1
kind: HelmRelease
metadata:
  name: docker-registry
  namespace: system
  annotations:
    flux.weave.works/automated: "true"
    flux.weave.works/tag.chart-image: semver:~0.2.2
spec:
  releaseName: docker-registry
  chart:
    git: git@github.com:Morriz/mostack
    path: charts/docker-registry
    ref: master
  valueFileSecrets:
  - name: docker-registry-secrets
  values: {}
