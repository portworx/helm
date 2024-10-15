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

{{/*
HTTP proxy enabled env.
*/}}
{{- define "proxy.noProxyEnv" -}}
{{- if .Values.proxy.httpProxy.noProxy }}
- name: NO_PROXY
  value: {{ .Values.proxy.httpProxy.noProxy }}
- name: no_proxy
  value: {{ .Values.proxy.httpProxy.noProxy }}
{{- end }}
{{- end }}

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
Check if the password is defined in values.yaml. If not, check existing Secret. If not, generate a random password.
*/}}
{{- define "getOrGeneratePassword" -}}
{{- if .Values.oidc.centralOIDC.defaultPassword | default "" | not -}}
  {{- if not (get .Values "generatedPassword") -}}
    {{- $secret := lookup "v1" "Secret" .Release.Namespace "pxcentral-keycloak-http" -}}
    {{- if $secret -}}
      {{- if $secret.data.password -}}
        {{- $_ := set .Values "generatedPassword" ($secret.data.password | b64dec) -}}
      {{- else -}}
        {{- $_ := set .Values "generatedPassword" (randAlphaNum 8) -}}
      {{- end -}}
    {{- else -}}
      {{- $_ := set .Values "generatedPassword" (randAlphaNum 8) -}}
    {{- end -}}
  {{- end -}}
  {{- .Values.generatedPassword -}}
{{- else -}}
  {{- .Values.oidc.centralOIDC.defaultPassword -}}
{{- end -}}
{{- end -}}
{{/*
Function to check if a value is empty or not
*/}}
{{- define "nonEmptyOrDefault" -}}
  {{- if and (not (empty .)) (ne . "") -}}
    {{- . -}}
  {{- else -}}
    {{- randAlpha 9 -}}
  {{- end -}}
{{- end }}

