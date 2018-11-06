apiVersion: helm.integrations.flux.weave.works/v1alpha2
kind: FluxHelmRelease
metadata:
  name: elk
  namespace: logging
  annotations:
    flux.weave.works/automated: "true"
    flux.weave.works/tag.chart-image: semver:~0.1
spec:
  namespace: logging
  chartGitPath: elk
  releaseName: elk
  values:
    slackUrl: {{SLACK_API_URL}}
    kibanaPassword: {{KIBANA_PASSWORD}}
    hostname: logging.{{CLUSTER_HOST}}
    tls: {{TLS_ENABLE}}
    containersLocation: {{CONTAINERS_LOCATION}}