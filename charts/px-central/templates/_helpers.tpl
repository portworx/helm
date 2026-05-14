{{/*
Expand the name of the chart.
*/}}
{{- define "px-central.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "px-central.fullname" -}}
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

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "px-central.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "px-central.labels" -}}
app.kubernetes.io/name: {{ template "px-central.name" . }}
app.kubernetes.io/instance: {{.Release.Name | quote }}
app.kubernetes.io/managed-by: {{.Release.Service | quote }}
helm.sh/chart: "{{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}"
app.kubernetes.io/version: {{ .Chart.Version | quote }}
{{- end }}


{{/*
Selector labels
*/}}
{{- define "px-central.selectorLabels" -}}
app.kubernetes.io/name: {{ include "px-central.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "px-central.noProxyList" -}}
{{- $default := "localhost,127.0.0.1,::1,[::]:10005,.svc,.svc.cluster.local,0.0.0.0,px-backup-ui,px-central-ui,pxcentral-apiserver,pxcentral-backend,pxcentral-frontend,pxcentral-keycloak-headless,pxcentral-keycloak-http,pxcentral-keycloak-postgresql,pxcentral-keycloak-postgresql-headless,pxcentral-lh-middleware,pxcentral-mysql," }}
{{- if .Values.pxbackup.enabled }}
  {{- $default = printf "%s%s" $default "alertmanager-operated,prometheus-operated,px-backup,px-backup-dashboard-prometheus,pxc-backup-mongodb-headless," }}
  {{- $default = printf "%s%s.%s," $default "px-backup" .Release.Namespace }}
{{- end }}
{{- if .Values.pxmonitor.enabled }}
  {{- $default = printf "%s%s" $default "pxcentral-grafana,pxcentral-cortex-nginx,pxcentral-cortex-cassandra-headless,pxcentral-cortex-cassandra,pxcentral-memcached-index-read,pxcentral-memcached-index-write,pxcentral-memcached,pxcentral-cortex-alertmanager-headless,pxcentral-cortex-alertmanager,pxcentral-cortex-configs,pxcentral-cortex-distributor,pxcentral-cortex-ingester,pxcentral-cortex-querier,pxcentral-cortex-query-frontend-headless,pxcentral-cortex-consul,pxcentral-cortex-query-frontend,pxcentral-cortex-ruler,pxcentral-cortex-table-manager,pxcentral-prometheus,"}}
{{- end }}
{{- if .Values.pxlicenseserver.enabled }}
  {{- $default = printf "%s%s" $default "pxcentral-license," }}
{{- end }}
{{- if not .Values.pxbackup.deployDedicatedMonitoringSystem }}
{{- $promHostname := regexReplaceAll "[/:].*" (trimPrefix "https://" (trimPrefix "http://" .Values.pxbackup.prometheusEndpoint)) "" -}}
{{- $amHostname := regexReplaceAll "[/:].*" (trimPrefix "https://" (trimPrefix "http://" .Values.pxbackup.alertmanagerEndpoint)) "" -}}
  {{- $default = printf "%s%s,%s," $default $promHostname $amHostname }}
{{- end }}
{{- printf "%s%s" $default .Values.proxy.httpProxy.noProxy }}
{{- end }}

{{/*
HTTP proxy enabled env.
*/}}
{{- define "proxy.proxyEnv" -}}
{{- if .Values.proxy.configSecretName }}
- name: http_proxy
  valueFrom:
    secretKeyRef:
      name: {{ .Values.proxy.configSecretName }}
      key: HTTP_PROXY
- name: https_proxy
  valueFrom:
    secretKeyRef:
      name: {{ .Values.proxy.configSecretName }}
      key: HTTPS_PROXY
- name: HTTP_PROXY
  valueFrom:
    secretKeyRef:
      name: {{ .Values.proxy.configSecretName }}
      key: HTTP_PROXY
- name: HTTPS_PROXY
  valueFrom:
    secretKeyRef:
      name: {{ .Values.proxy.configSecretName }}
      key: HTTPS_PROXY
- name: NO_PROXY
  valueFrom:
    secretKeyRef:
      name: {{ .Values.proxy.configSecretName }}
      key: NO_PROXY
- name: no_proxy
  valueFrom:
    secretKeyRef:
      name: {{ .Values.proxy.configSecretName }}
      key: NO_PROXY
{{- end }}
{{- if .Values.proxy.http }}
- name: HTTP_PROXY
  value: {{ .Values.proxy.http }}
- name: http_proxy
  value: {{ .Values.proxy.http }}
{{- end }}
{{- if .Values.proxy.https }}
- name: HTTPS_PROXY
  value: {{ .Values.proxy.https }}
- name: https_proxy
  value: {{ .Values.proxy.https }}
{{- end }}
{{- if .Values.proxy.httpProxy.noProxy }}
- name: NO_PROXY
  value: {{ include "px-central.noProxyList" . | quote }}
- name: no_proxy
  value: {{ include "px-central.noProxyList" . | quote }}
{{- end }}
{{- end }}


{{- define "serviceMesh.env" -}}
{{- if .Values.istio.enabled -}}
- name: SERVICE_MESH
  value: istio
{{- else if .Values.linkerd.enabled -}}
- name: SERVICE_MESH
  value: linkerd
{{- else -}}
- name: SERVICE_MESH
  value: ""
{{- end -}}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "px-central.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "px-central.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Renders a value that contains template.
Usage:
{{ include "pxcentral.render" ( dict "value" .Values.path.to.the.Value "context" $) }}
*/}}
{{- define "pxcentral.render" -}}
    {{- if typeIs "string" .value }}
        {{- tpl .value .context }}
    {{- else }}
        {{- tpl (.value | toYaml) .context }}
    {{- end }}
{{- end -}}
