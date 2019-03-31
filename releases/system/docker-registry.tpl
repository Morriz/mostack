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
  valueFileSecrets:
  - name: drone-secrets
  values: {}
