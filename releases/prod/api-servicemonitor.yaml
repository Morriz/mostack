apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  labels:
    app: api
    release: team-frontend-api-prod
    prometheus: team-frontend-prometheus
  name: team-frontend-api-prod
spec:
  jobLabel: team-frontend-api-prod
  selector:
    matchLabels:
      app: api
      release: team-frontend-api-prod
  namespaceSelector:
    matchNames:
    - team-frontend
  endpoints:
  - port: http
    interval: 30s
