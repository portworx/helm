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
{{- if .Values.pxbackup.enabled }}
app.kubernetes.io/part-of: px-backup
{{- end }}
{{- end }}

{{/*
Part-of label for nested templates
*/}}
{{- define "px-central.partOfLabel" -}}
{{- if .Values.pxbackup.enabled }}
app.kubernetes.io/part-of: px-backup
{{- end }}
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
      optional: true
- name: https_proxy
  valueFrom:
    secretKeyRef:
      name: {{ .Values.proxy.configSecretName }}
      key: HTTPS_PROXY
      optional: true
- name: HTTP_PROXY
  valueFrom:
    secretKeyRef:
      name: {{ .Values.proxy.configSecretName }}
      key: HTTP_PROXY
      optional: true
- name: HTTPS_PROXY
  valueFrom:
    secretKeyRef:
      name: {{ .Values.proxy.configSecretName }}
      key: HTTPS_PROXY
      optional: true
- name: NO_PROXY
  valueFrom:
    secretKeyRef:
      name: {{ .Values.proxy.configSecretName }}
      key: NO_PROXY
      optional: true
- name: no_proxy
  valueFrom:
    secretKeyRef:
      name: {{ .Values.proxy.configSecretName }}
      key: NO_PROXY
      optional: true
{{- end }}
{{- /* When only one of proxy.http / proxy.https is set, default
       the other from it. HTTPS-only flows (e.g. telemetry OSB/Pure1 registration)
       must still route through a single corporate CONNECT proxy configured via
       proxy.http only. Defaulting both protocols from one is chart-wide safe. */ -}}
{{- if or .Values.proxy.http .Values.proxy.https }}
- name: HTTP_PROXY
  value: {{ .Values.proxy.http | default .Values.proxy.https }}
- name: http_proxy
  value: {{ .Values.proxy.http | default .Values.proxy.https }}
- name: HTTPS_PROXY
  value: {{ .Values.proxy.https | default .Values.proxy.http }}
- name: https_proxy
  value: {{ .Values.proxy.https | default .Values.proxy.http }}
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

{{/*
px.image resolves a fully-qualified image ref for a given image key.
Tag resolution: .Values.images.<key>.tag (override) -> hardcoded tag (external) -> .Values.images.version (PX-owned).
*/}}
{{- define "px.image" -}}
{{- $key  := .key -}}
{{- $root := .root -}}
{{- $images := dict
    "pxcentralApiServerImage"               (dict "name" "pxcentral-onprem-api-base")
    "pxcentralFrontendImage"                (dict "name" "pxcentral-onprem-ui-frontend-private")
    "pxcentralBackendImage"                 (dict "name" "pxcentral-onprem-ui-backend-private")
    "pxcentralMiddlewareImage"              (dict "name" "pxcentral-onprem-ui-lhbackend-private")
    "postInstallSetupImage"                 (dict "name" "pxcentral-onprem-hook-base")
    "preSetupHookImage"                     (dict "name" "pxcentral-onprem-hook-base")
    "keycloakLoginThemeImage"               (dict "name" "sb-keycloak-login-theme")
    "pxBackupImage"                         (dict "name" "px-backup-base")
    "telemetryDataCollectorImage"           (dict "name" "px-backup-telemetry-collector-base")
    "licenseServerImage"                    (dict "name" "px-els")
    "keycloakBackendImage"                  (dict "name" "postgresql"                 "tag" "18.4")
    "keycloakFrontendImage"                 (dict "name" "keycloak"                   "tag" "26.5.7_v2")
    "keycloakInitContainerImage"            (dict "name" "busybox"                    "tag" "1.35.0")
    "mysqlImage"                            (dict "name" "mysql"                      "tag" "8.4.9")
    "mysqlInitImage"                        (dict "name" "busybox"                    "tag" "1.35.0")
    "mongodbImage"                          (dict "name" "mongodb"                    "tag" "8.0.20")
    "pxBackupPrometheusImage"               (dict "name" "prometheus"                 "tag" "v3.11.3")
    "pxBackupAlertmanagerImage"             (dict "name" "alertmanager"               "tag" "v0.32.1")
    "pxBackupPrometheusOperatorImage"       (dict "name" "prometheus-operator"        "tag" "v0.91.0")
    "pxBackupPrometheusConfigReloaderImage" (dict "name" "prometheus-config-reloader" "tag" "v0.91.0")
    "telemetryEnvoyImage"                   (dict "name" "edge-envoy"                 "tag" "2.0.109")
    "telemetryRegistrationImage"            (dict "name" "ccm-go"                     "tag" "1.4.42")
    "telemetryMetricsCollectorImage"        (dict "name" "realtime-metrics"           "tag" "1.0.36")
    "telemetryLogUploadImage"               (dict "name" "log-upload"                 "tag" "px-1.1.148")
-}}
{{- $pxVersion := "3.3.0-fc1" -}}
{{- $img      := get $images $key -}}
{{- $name     := get $img "name" -}}
{{- $hardTag  := get $img "tag" -}}
{{- $override := dig $key "tag" "" $root.Values.images -}}
{{- $tag      := default (default $pxVersion $hardTag) $override -}}
{{- $registry := default "docker.io"  (default (dig $key "registry" "" $root.Values.images) $root.Values.images.registry) -}}
{{- $repo     := default "portworx"   (default (dig $key "repo"     "" $root.Values.images) $root.Values.images.repo) -}}
{{- printf "%s/%s/%s:%s" $registry $repo $name $tag -}}
{{- end -}}
