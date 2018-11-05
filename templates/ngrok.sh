authtoken: {{NGROK_TOKEN}}
log_level: info
log: stdout
region: eu
update: true
tunnels:
  dev:
    proto: http
    addr: 80
    hostname: '*.{{CLUSTER_HOST}}'
    bind_tls: false
  dev-tls:
    proto: tls
    addr: 443
    hostname: '*.{{CLUSTER_HOST}}'