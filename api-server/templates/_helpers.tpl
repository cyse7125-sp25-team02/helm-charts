{{/* Generate basic labels */}}
{{- define "test-server.labels" -}}
app.kubernetes.io/name: {{ .Chart.Name | quote }}
app.kubernetes.io/instance: {{ .Release.Name | quote }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: "Helm"
{{- end -}}