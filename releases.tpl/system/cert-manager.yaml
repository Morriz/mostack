apiVersion: helm.integrations.flux.weave.works/v1alpha2
kind: FluxHelmRelease
metadata:
  name: cert-manager
  namespace: system
  annotations:
    flux.weave.works/automated: "true"
    flux.weave.works/tag.chart-image: v0.4.1
spec:
  namespace: system
  chartGitPath: cert-manager
  releaseName: cert-manager
  values:
    ingressShim:
      defaultIssuerName: letsencrypt-staging
      defaultIssuerKind: ClusterIssuer