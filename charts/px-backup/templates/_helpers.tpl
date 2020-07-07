{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "px-backup.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "px-backup.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "px-backup.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "px-backup.labels" -}}
app.kubernetes.io/name: {{ template "px-backup.name" . }}
helm.sh/chart: "{{.Chart.Name}}-{{.Chart.Version}}"
app.kubernetes.io/instance: {{.Release.Name | quote }}
app.kubernetes.io/version: {{ .Chart.Version | quote }}
app.kubernetes.io/managed-by: {{.Release.Service | quote }}
{{- end -}}

{{- define "ingress-controller.labels" -}}
app.kubernetes.io/name: ingress-nginx
helm.sh/chart: ingress-nginx-2.0.2
app.kubernetes.io/instance: ingress-nginx
app.kubernetes.io/version: 0.31.1
app.kubernetes.io/component: controller
app.kubernetes.io/managed-by: {{.Release.Service | quote }}
{{- end -}}

{{- define "ingress-controller-webhook.labels" -}}
app.kubernetes.io/name: ingress-nginx
helm.sh/chart: ingress-nginx-2.0.2
app.kubernetes.io/instance: ingress-nginx
app.kubernetes.io/version: 0.31.1
app.kubernetes.io/component: admission-webhook
app.kubernetes.io/managed-by: {{.Release.Service | quote }}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "px-backup.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "px-backup.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}


