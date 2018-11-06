apiVersion: helm.integrations.flux.weave.works/v1alpha2
kind: FluxHelmRelease
metadata:
  name: team-frontend-api-prod
  namespace: prod
  annotations:
    flux.weave.works/automated: "true"
    flux.weave.works/tag.chart-image: semver:~0.1
spec:
  namespace: prod
  chartGitPath: api
  releaseName: team-frontend-api-prod
  values:
    image: reg.dev.idiotz.nl/api:latest
    ingress:
      tls: {{TLS_ENABLE}}
      hostname: api.{{CLUSTER_HOST}}
      certmanager.k8s.io/cluster-issuer: letsencrypt-production
    autoscaler:
      maxReplicas: 10
      targetCPUUtilizationPercentage: 50
