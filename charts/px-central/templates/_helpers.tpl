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
px.imageCatalog is the single source of truth for chart images: name, module and,
for externally-owned images, a hardcoded tag. PX-owned images (no tag) get the chart's PX version.
module matches the preflight-check hook's module gating (pxCentral / pxBackup ).
Returned as JSON; consume with: include "px.imageCatalog" . | fromJson

Third-party images (legal: origin and license must stay documented; keep in sync with README.md "Third-party images")
These are open-source images Portworx does not build. They are retagged from the public upstream image
(unmodified unless noted) and published as docker.io/portworx/<image>, mirrored by pure-artifactory
px-docker-remote, by the DevOps job DevOps/docker-images/publish-public-docker-image (one PXDO ticket per
retag, e.g. PXDO-14194). The tag is the upstream release tag; bump it only after that tag exists in
docker.io/portworx (versions.yaml lists the published set). When adding or changing an upstream image,
update this list and the README table in the same change.

  portworx image               upstream source                                         license (main software)
  postgresql                   docker.io/library/postgres                              PostgreSQL License
  keycloak                     quay.io/keycloak/keycloak, rebuilt by Portworx ("_vN")  Apache-2.0
  mysql                        docker.io/library/mysql                                 GPL-2.0
  busybox                      docker.io/library/busybox                               GPL-2.0
  mongodb                      docker.io/library/mongo                                 SSPL-1.0
  mongodb (mongodbImageMap)    docker.io/bitnami/mongodb (5.x-7.x upgrade steps only)  SSPL-1.0; Bitnami packaging Apache-2.0
  prometheus                   quay.io/prometheus/prometheus                           Apache-2.0
  alertmanager                 quay.io/prometheus/alertmanager                         Apache-2.0
  prometheus-operator          quay.io/prometheus-operator/prometheus-operator         Apache-2.0
  prometheus-config-reloader   quay.io/prometheus-operator/prometheus-config-reloader  Apache-2.0

postgresql was previously the Bitnami image; the /bitnami/postgresql paths left in pxcentral-keycloak.yaml
are directory names only (PGDATA points the official image at them).
Not third-party: edge-envoy, ccm-go, realtime-metrics and log-upload are Portworx-built telemetry images
on their own release cadence; entries without a tag are PX-owned and built at the PX version.
*/}}
{{- define "px.imageCatalog" -}}
{{- $images := dict
    "pxcentralApiServerImage"               (dict "name" "pxcentral-onprem-api-base"             "module" "pxCentral")
    "pxcentralFrontendImage"                (dict "name" "pxcentral-onprem-ui-frontend-private"  "module" "pxCentral")
    "pxcentralBackendImage"                 (dict "name" "pxcentral-onprem-ui-backend-private"   "module" "pxCentral")
    "pxcentralMiddlewareImage"              (dict "name" "pxcentral-onprem-ui-lhbackend-private" "module" "pxCentral")
    "postInstallSetupImage"                 (dict "name" "pxcentral-onprem-hook-base"            "module" "pxCentral")
    "preSetupHookImage"                     (dict "name" "pxcentral-onprem-hook-base"            "module" "pxCentral")
    "keycloakLoginThemeImage"               (dict "name" "sb-keycloak-login-theme"               "module" "pxCentral")
    "keycloakBackendImage"                  (dict "name" "postgresql"                 "tag" "18.4"       "module" "pxCentral")
    "keycloakFrontendImage"                 (dict "name" "keycloak"                   "tag" "26.6.4_v2"  "module" "pxCentral")
    "keycloakInitContainerImage"            (dict "name" "busybox"                    "tag" "1.35.0"     "module" "pxCentral")
    "mysqlImage"                            (dict "name" "mysql"                      "tag" "8.4.10"     "module" "pxCentral")
    "mysqlInitImage"                        (dict "name" "busybox"                    "tag" "1.35.0"     "module" "pxCentral")
    "pxBackupImage"                         (dict "name" "px-backup-base"                        "module" "pxBackup")
    "telemetryDataCollectorImage"           (dict "name" "px-backup-telemetry-collector-base"    "module" "pxBackup")
    "mongodbImage"                          (dict "name" "mongodb"                    "tag" "8.0.20"     "module" "pxBackup")
    "pxBackupPrometheusImage"               (dict "name" "prometheus"                 "tag" "v3.13.1"    "module" "pxBackup")
    "pxBackupAlertmanagerImage"             (dict "name" "alertmanager"               "tag" "v0.33.0"    "module" "pxBackup")
    "pxBackupPrometheusOperatorImage"       (dict "name" "prometheus-operator"        "tag" "v0.92.0"    "module" "pxBackup")
    "pxBackupPrometheusConfigReloaderImage" (dict "name" "prometheus-config-reloader" "tag" "v0.92.0"    "module" "pxBackup")
    "telemetryEnvoyImage"                   (dict "name" "edge-envoy"                 "tag" "2.0.115"    "module" "pxBackup")
    "telemetryRegistrationImage"            (dict "name" "ccm-go"                     "tag" "1.4.54"     "module" "pxBackup")
    "telemetryMetricsCollectorImage"        (dict "name" "realtime-metrics"           "tag" "1.0.38"     "module" "pxBackup")
    "telemetryLogUploadImage"               (dict "name" "log-upload"                 "tag" "px-1.1.155" "module" "pxBackup")
-}}
{{- toJson $images -}}
{{- end -}}

{{/*
px.imageParts resolves registry/repo/imageName/tag/module for one image key, as JSON.
Tag resolution: .Values.images.<key>.tagOverride -> catalog tag (external) -> .Chart.AppVersion (PX-owned).
.Values.images.<key>.tag is ignored so a values file carried over from an older release cannot pin old images.
Registry/repo resolution: .Values.images.<registry|repo> (global) -> .Values.images.<key>.<registry|repo> -> docker.io/portworx.
Usage: include "px.imageParts" (dict "key" "<imageKey>" "root" .) | fromJson
*/}}
{{- define "px.imageParts" -}}
{{- $key  := .key -}}
{{- $root := .root -}}
{{- $pxVersion := $root.Chart.AppVersion -}}
{{- $img      := required (printf "px.image: unknown image key %q" $key) (get (include "px.imageCatalog" $root | fromJson) $key) -}}
{{- $override := dig $key "tagOverride" "" $root.Values.images -}}
{{- $tag      := default (default $pxVersion $img.tag) $override -}}
{{- $registry := default "docker.io"  (default (dig $key "registry" "" $root.Values.images) $root.Values.images.registry) -}}
{{- $repo     := default "portworx"   (default (dig $key "repo"     "" $root.Values.images) $root.Values.images.repo) -}}
{{- toJson (dict "registry" $registry "repo" $repo "imageName" $img.name "tag" $tag "module" $img.module) -}}
{{- end -}}

{{/*
px.image resolves a fully-qualified image ref for a given image key.
Usage: include "px.image" (dict "key" "<imageKey>" "root" .)
*/}}
{{- define "px.image" -}}
{{- $p := include "px.imageParts" . | fromJson -}}
{{- printf "%s/%s/%s:%s" $p.registry $p.repo $p.imageName $p.tag -}}
{{- end -}}

{{/*
px.imagesJson renders the IMAGES payload for the preflight-check hook
(pxcentral-hook utils.GetImageList): global registry/repo plus one fully-resolved
{registry, repo, imageName, tag, module} entry per catalog image, so the hook
validates exactly the refs the workloads use.
*/}}
{{- define "px.imagesJson" -}}
{{- $root := . -}}
{{- $out := dict "registry" (default "" .Values.images.registry) "repo" (default "" .Values.images.repo) -}}
{{- range $key, $img := include "px.imageCatalog" . | fromJson -}}
{{- $_ := set $out $key (include "px.imageParts" (dict "key" $key "root" $root) | fromJson) -}}
{{- end -}}
{{- toJson $out -}}
{{- end -}}

{{/*
px.requireVersionMatch fails an install or upgrade whose pxbackup.version differs from the chart version, so the deployed version stays traceable from the values.
Pre-release suffixes are ignored: pxbackup.version 3.3.0 matches chart 3.3.0 even when the images are 3.3.0-fc1.
*/}}
{{- define "px.requireVersionMatch" -}}
{{- $requested := toString .Values.pxbackup.version -}}
{{- $chartCore := regexFind "[0-9]+\\.[0-9]+\\.[0-9]+" .Chart.Version -}}
{{- if ne $chartCore (regexFind "[0-9]+\\.[0-9]+\\.[0-9]+" $requested) -}}
{{- fail (printf "Version mismatch: pxbackup.version is %q but this is the %s chart. Set pxbackup.version to %s in your values file." $requested .Chart.Version $chartCore) -}}
{{- end -}}
{{- end -}}

{{/*
px.rejectDowngrade fails a helm upgrade to a chart older than the running px-backup; px.requireVersionMatch keeps pxbackup.version equal to the chart version.
The running version is the app.kubernetes.io/version label (the chart version of the last applied release) on the px-backup Deployment.
Skipped when that Deployment cannot be looked up: fresh install, helm template, client-side dry run, ArgoCD render.
*/}}
{{- define "px.rejectDowngrade" -}}
{{- if .Release.IsUpgrade -}}
{{- $deployment := lookup "apps/v1" "Deployment" .Release.Namespace "px-backup" -}}
{{- $running := dig "metadata" "labels" "app.kubernetes.io/version" "" $deployment | toString -}}
{{- $runningCore := regexFind "[0-9]+\\.[0-9]+\\.[0-9]+" $running -}}
{{- if $runningCore -}}
{{- if semverCompare (printf "<%s" $runningCore) (regexFind "[0-9]+\\.[0-9]+\\.[0-9]+" .Chart.Version) -}}
{{- fail (printf "Downgrade rejected: px-backup %s is running but this is the %s chart. Downgrades are not supported; use helm rollback to return to an earlier revision." $running .Chart.Version) -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}
