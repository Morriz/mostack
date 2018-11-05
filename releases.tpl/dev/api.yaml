---
apiVersion: helm.integrations.flux.weave.works/v1alpha2
kind: FluxHelmRelease
metadata:
  name: team-frontend-api-dev
  namespace: dev
  annotations:
    flux.weave.works/automated: "true"
    flux.weave.works/tag.chart-image: glob:dev-*
spec:
  namespace: dev
  chartGitPath: api
  releaseName: team-frontend-api-dev
  values:
    replicaCount: 1
    image:
      repository: {{REGISTRY_HOST}}/api
      # repository: localhost:5000/api
    ingress:
      tls: {{TLS_ENABLE}}
      hostname: api.{{CLUSTER_HOST}}
      certmanager.k8s.io/cluster-issuer: letsencrypt-staging
    prometheus: team-frontend-prometheus