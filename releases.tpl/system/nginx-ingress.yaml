apiVersion: helm.integrations.flux.weave.works/v1alpha2
kind: FluxHelmRelease
metadata:
  name: nginx-ingress
  namespace: system
  annotations:
    flux.weave.works/automated: "true"
    flux.weave.works/tag.chart-image: semver:~0.1
spec:
  namespace: system
  chartGitPath: nginx-ingress
  releaseName: nginx-ingress
  values:
    rbac:
      create: {{RBAC_ENABLE}}
    controller:
      config:
        ssl-redirect: "{{TLS_ENABLE}}"
        hsts: "{{TLS_ENABLE}}"
        disable-ipv6: "true"
      stats:
        enabled: true
      hostNetwork: {{ISMINIKUBE}}
      service:
        type: ClusterIP
        # nodePorts:
        #   http: 32080
        #   https: 32443

      # resources:
      #    limits:
      #      cpu: 100m
      #      memory: 64Mi
      #    requests:
      #      cpu: 100m
      #      memory: 64Mi
