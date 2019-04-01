apiVersion: v1
kind: Secret
metadata:
  name: {{ template drone.sourceControlSecret }}
  labels:
    app: {{ template "drone.name" . }}
    chart: "{{ .Chart.Name }}-{{ .Chart.Version }}"
    release: "{{ .Release.Name }}"
    heritage: "{{ .Release.Service }}"
type: Opaque
data:
{{- if eq .Values.sourceControl.provider "github" -}}
  {{ .Values.sourceControl.github.clientSecretKey }}: "{{ .Values.sourceControl.github.clientSecret | b64enc }}"
{{- end -}}
{{- if eq .Values.sourceControl.provider "gitlab" -}}
  {{ .Values.sourceControl.gitlab.clientSecretKey }}: "{{ .Values.sourceControl.gitlab.clientSecret | b64enc }}"
{{- end -}}
{{- if eq .Values.sourceControl.provider "bitbucketCloud" -}}
  {{ .Values.sourceControl.bitbucketCloud.clientSecretKey }}: "{{ .Values.sourceControl.bitbucketCloud.clientSecret | b64enc }}"
{{- end -}}
{{- if eq .Values.sourceControl.provider "bitbucketServer" -}}
  {{ .Values.sourceControl.bitbucketServer.consumerKey }}: "{{ .Values.sourceControl.bitbucketServer.consumersSecret | b64enc }}"
  {{ .Values.sourceControl.bitbucketServer.privateKey }}: "{{ .Values.sourceControl.bitbucketServer.privateSecret | b64enc }}"
{{- end -}}