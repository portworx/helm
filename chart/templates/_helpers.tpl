{{/*
Common name for all resources.
*/}}
{{- define "pg.name" -}}
{{ .Values.name | default "postgres" }}
{{- end -}}

{{/*
Instance identifier (doubles as namespace name).
*/}}
{{- define "pg.instance" -}}
{{ .Values.instance }}
{{- end -}}

{{/*
Standard labels applied to every resource.
*/}}
{{- define "pg.labels" -}}
app.kubernetes.io/name: {{ include "pg.name" . }}
app.kubernetes.io/instance: {{ include "pg.instance" . }}
app.kubernetes.io/part-of: pxbackup-poc
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
{{- end -}}

{{/*
Selector labels (subset used in matchLabels).
*/}}
{{- define "pg.selectorLabels" -}}
app.kubernetes.io/name: {{ include "pg.name" . }}
app.kubernetes.io/instance: {{ include "pg.instance" . }}
{{- end -}}
