{{/*
Base name for the chart/release.
*/}}
{{- define "px-observability-ui.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Fully qualified app name, used for the UI's own resources.
*/}}
{{- define "px-observability-ui.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{- define "px-observability-ui.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "px-observability-ui.labels" -}}
helm.sh/chart: {{ include "px-observability-ui.chart" . }}
{{ include "px-observability-ui.selectorLabels" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "px-observability-ui.selectorLabels" -}}
app.kubernetes.io/name: {{ include "px-observability-ui.fullname" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
ServiceAccount name used by the UI Deployment.
*/}}
{{- define "px-observability-ui.serviceAccountName" -}}
{{- if .Values.ui.serviceAccount.create }}
{{- default (include "px-observability-ui.fullname" .) .Values.ui.serviceAccount.name }}
{{- else }}
{{- required "ui.serviceAccount.name is required when ui.serviceAccount.create is false" .Values.ui.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
PX Cache Agent's own resource name (kept distinct from the UI's fullname since it's a
separate component copied from its own repo — see docs/helm-chart.md).
*/}}
{{- define "px-observability-ui.cacheAgent.fullname" -}}
{{- printf "px-cache-agent" }}
{{- end }}

{{- define "px-observability-ui.cacheAgent.labels" -}}
helm.sh/chart: {{ include "px-observability-ui.chart" . }}
{{ include "px-observability-ui.cacheAgent.selectorLabels" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "px-observability-ui.cacheAgent.selectorLabels" -}}
app.kubernetes.io/name: {{ include "px-observability-ui.cacheAgent.fullname" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: controller-manager
{{- end }}
