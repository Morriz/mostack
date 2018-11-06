apiVersion: helm.integrations.flux.weave.works/v1alpha2
kind: FluxHelmRelease
metadata:
  name: weave-scope
  namespace: system
  annotations:
    flux.weave.works/automated: "true"
    flux.weave.works/tag.chart-image: semver:~0.9.3
spec:
  namespace: system
  chartGitPath: weave-scope
  values:
    global:
      image:
        tag: "1.9.1"
