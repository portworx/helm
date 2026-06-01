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

{{/*
=============================================================================
Telemetry Helper Templates
=============================================================================
*/}}

{{/*
Extract appliance-id from existing telemetry ConfigMap during upgrades.
Returns the existing appliance-id if found, otherwise returns placeholder.
*/}}
{{- define "telemetry.lookupApplianceID" -}}
{{- $existingConfigMap := lookup "v1" "ConfigMap" .namespace .configMapName }}
{{- $applianceID := "APPLIANCE_ID_PLACEHOLDER" }}
{{- if $existingConfigMap }}
  {{- $existingConfig := index $existingConfigMap.data .configKey | default "" }}
  {{- if $existingConfig }}
    {{- $match := regexFind "key: \"appliance-id\"\\s+value: \"[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\"" $existingConfig }}
    {{- if $match }}
      {{- $applianceID = regexReplaceAll "key: \"appliance-id\"\\s+value: \"([0-9a-f-]+)\"" $match "${1}" }}
    {{- end }}
  {{- end }}
{{- end }}
{{- $applianceID }}
{{- end -}}

{{/*
Extract endpoint from existing telemetry ConfigMap during upgrades.
Returns the existing endpoint if found, otherwise returns the provided placeholder.
Each ConfigMap contains only one Pure1 endpoint, so no need to distinguish types.
*/}}
{{- define "telemetry.lookupEndpoint" -}}
{{- $existingConfigMap := lookup "v1" "ConfigMap" .namespace .configMapName }}
{{- $endpoint := .placeholder }}
{{- if $existingConfigMap }}
  {{- $existingConfig := index $existingConfigMap.data .configKey | default "" }}
  {{- if $existingConfig }}
    {{- $match := regexFind "address: [a-z0-9.-]+\\.purestorage\\.com" $existingConfig }}
    {{- if $match }}
      {{- $endpoint = regexReplaceAll "address: ([a-z0-9.-]+)" $match "${1}" }}
    {{- end }}
  {{- end }}
{{- end }}
{{- $endpoint }}
{{- end -}}

{{/*
Init container that blocks envoy startup until the px-backup server's
configmap_manager has replaced ENDPOINT_*_PLACEHOLDER strings in the
mounted envoy ConfigMap. Used by all three telemetry pods
(logs-collector, metrics-collector, registration).

Image choice: reuses `mysqlInitImage` (the busybox image already used by
pxcentral-ui's init-mysql container). This avoids introducing a new image dependency

Hard-coded knobs:
  TIMEOUT  = 600s — per-attempt cap; on timeout exits 1 so kubelet retries.
  INTERVAL = 30s  — polling cadence; sets recovery latency and log volume.

Parameters (passed as a dict):
  root        — `$` from the caller (gives access to .Values)
  mountPath   — where the envoy-config volume is mounted in the pod
  configFile  — config filename inside mountPath (e.g. "envoy-config.yaml")
*/}}
{{- define "px-central.envoyConfigWaitInit" -}}
- name: wait-for-envoy-config
  image: {{ printf "%s/%s/%s:%s" (default .root.Values.images.mysqlInitImage.registry .root.Values.images.registry) (default .root.Values.images.mysqlInitImage.repo .root.Values.images.repo) .root.Values.images.mysqlInitImage.imageName .root.Values.images.mysqlInitImage.tag }}
  imagePullPolicy: {{ .root.Values.images.pullPolicy }}
  command:
  - sh
  - -c
  - |
    sleep 5
    TIMEOUT=600
    INTERVAL=30
    ELAPSED=0
    while grep -q "PLACEHOLDER" {{ .mountPath }}/{{ .configFile }}; do
      if [ $ELAPSED -ge $TIMEOUT ]; then
        echo "ERROR: Envoy ConfigMap still has PLACEHOLDER after ${TIMEOUT}s - check px-backup server configmap_manager"
        exit 1
      fi
      echo "Envoy ConfigMap not ready yet (${ELAPSED}/${TIMEOUT}s), waiting..."
      sleep $INTERVAL
      ELAPSED=$((ELAPSED + INTERVAL))
    done
    echo "Envoy ConfigMap is ready"
  volumeMounts:
  - name: envoy-config
    mountPath: {{ .mountPath }}
    readOnly: true
{{- end -}}
