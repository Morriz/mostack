apiVersion: helm.integrations.flux.weave.works/v1alpha2
kind: FluxHelmRelease
metadata:
  name: metrics-server
  namespace: kube-system
  annotations:
    flux.weave.works/automated: "true"
    flux.weave.works/tag.chart-image: semver:~0.1
spec:
  namespace: kube-system
  chartGitPath: metrics-server
  releaseName: metrics-server
  values:
    args:
      - --source=kubernetes.summary_api:''
      - --metric-resolution=10s