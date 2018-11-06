apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  labels:
    app: api
    release: team-frontend-api-dev
    prometheus: team-frontend-prometheus
  name: team-frontend-api-dev
spec:
  jobLabel: team-frontend-api-dev
  selector:
    matchLabels:
      app: api
      release: team-frontend-api-dev
  namespaceSelector:
    matchNames:
    - team-frontend
  endpoints:
  - port: http
    interval: 30s
