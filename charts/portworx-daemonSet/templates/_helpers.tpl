{{/* Gets the correct API Version based on the version of the cluster
*/}}

{{- define "rbac.apiVersion" -}}
{{- if semverCompare ">= 1.8" .Capabilities.KubeVersion.GitVersion -}}
"rbac.authorization.k8s.io/v1"
{{- else -}}
"rbac.authorization.k8s.io/v1beta1"
{{- end -}}
{{- end -}}


{{- define "px.labels" -}}
chart: "{{ .Chart.Name }}-{{ .Chart.Version }}"
heritage: {{ .Release.Service | quote }}
release: {{ .Release.Name | quote }}
{{- end -}}

{{- define "driveOpts" }}
{{ $v := .Values.installOptions.drives | split "," }}
{{$v._0}}
{{- end -}}

{{- define "px.kubernetesVersion" -}}
{{$version := .Capabilities.KubeVersion.GitVersion | regexFind "^v\\d+\\.\\d+\\.\\d+"}}{{$version}}
{{- end -}}

{{- define "px.kubectlImageTag" -}}
{{$version := .Capabilities.KubeVersion.GitVersion | regexFind "^v\\d+\\.\\d+\\.\\d+" | trimPrefix "v" | split "."}}
{{- $major := index $version "_0" -}}
{{- $minor := index $version "_1" -}}
{{printf "%s.%s" $major $minor }}
{{- end -}}

{{- define "px.getImage" -}}
{{- if (.Values.customRegistryURL) -}}
    {{- if (eq "/" (.Values.customRegistryURL | regexFind "/")) -}}
        {{- if .Values.openshiftInstall -}}
            {{ cat (trim .Values.customRegistryURL) "/px-monitor" | replace " " ""}}
        {{- else -}}
            {{ cat (trim .Values.customRegistryURL) "/oci-monitor" | replace " " ""}}
        {{- end -}}
    {{- else -}}
        {{- if .Values.openshiftInstall -}}
            {{cat (trim .Values.customRegistryURL) "/portworx/px-monitor" | replace " " ""}}
        {{- else -}}
            {{cat (trim .Values.customRegistryURL) "/portworx/oci-monitor" | replace " " ""}}
        {{- end -}}
    {{- end -}}
{{- else -}}
    {{- if .Values.openshiftInstall -}}
        {{ "registry.connect.redhat.com/portworx/px-monitor" }}
    {{- else -}}
        {{ "portworx/oci-monitor" }}
    {{- end -}}
{{- end -}}
{{- end -}}

{{- define "px.getStorkImage" -}}
{{- if (.Values.customRegistryURL) -}}
    {{- if (eq "/" (.Values.customRegistryURL | regexFind "/")) -}}
        {{ cat (trim .Values.customRegistryURL) "/stork" | replace " " ""}}
    {{- else -}}
        {{cat (trim .Values.customRegistryURL) "/openstorage/stork" | replace " " ""}}
    {{- end -}}
{{- else -}}
    {{ "openstorage/stork" }}
{{- end -}}
{{- end -}}

{{- define "px.getk8sImages" -}}
{{- $version := .Capabilities.KubeVersion.GitVersion -}}
{{- if (.Values.customRegistryURL) -}}
    {{- if (eq "/" (.Values.customRegistryURL | regexFind "/")) -}}
        {{ trim .Values.customRegistryURL }}
    {{- else -}}
        {{- if or (or (and (semverCompare ">= 1.16.14" $version ) (semverCompare "<=1.17.0"  $version)) (and (semverCompare ">= 1.17.10" $version) (semverCompare "<=1.18.0" $version ))) (semverCompare ">=1.18.7" $version) -}}
           {{cat (trim .Values.customRegistryURL) "/registry.k8s.io" | replace " " ""}}
        {{- else -}}
           {{cat (trim .Values.customRegistryURL) "/gcr.io/google_containers" | replace " " ""}}
        {{- end -}}
    {{- end -}}
{{- else -}}
     {{- if or (or (and (semverCompare ">= 1.16.14" $version ) (semverCompare "<=1.17.0"  $version)) (and (semverCompare ">= 1.17.10" $version) (semverCompare "<=1.18.0" $version ))) (semverCompare ">=1.18.7" $version) -}}
        {{ "registry.k8s.io" }}
     {{- else -}}
        {{ "gcr.io/google_containers" }}
    {{- end -}}
{{- end -}}
{{- end -}}


{{- define "px.getPauseImage" -}}
{{- if (.Values.customRegistryURL) -}}
    {{- if (eq "/" (.Values.customRegistryURL | regexFind "/")) -}}
        {{ trim .Values.customRegistryURL }}
    {{- else -}}
        {{cat (trim .Values.customRegistryURL) "/registry.k8s.io" | replace " " ""}}
    {{- end -}}
{{- else -}}
        {{ "registry.k8s.io" }}
{{- end -}}
{{- end -}}

{{- define "px.getcsiImages" -}}
{{- if (.Values.customRegistryURL) -}}
    {{- if (eq "/" (.Values.customRegistryURL | regexFind "/")) -}}
        {{ trim .Values.customRegistryURL }}
    {{- else -}}
        {{cat (trim .Values.customRegistryURL) "/quay.io/k8scsi" | replace " " ""}}
    {{- end -}}
{{- else -}}
        {{ "quay.io/k8scsi" }}
{{- end -}}
{{- end -}}

{{- define "px.getLighthouseImages" -}}
{{- if (.Values.customRegistryURL) -}}
    {{- if (eq "/" (.Values.customRegistryURL | regexFind "/")) -}}
        {{ trim .Values.customRegistryURL }}
    {{- else -}}
        {{cat (trim .Values.customRegistryURL) "/portworx" | replace " " ""}}
    {{- end -}}
{{- else -}}
        {{ "portworx" }}
{{- end -}}
{{- end -}}

{{- define "px.registryConfigType" -}}
{{- if semverCompare ">=1.9" .Capabilities.KubeVersion.GitVersion -}}
".dockerconfigjson"
{{- else -}}
".dockercfg"
{{- end -}}
{{- end -}}

{{/*
Create the name of the service account to use for hooks
*/}}
{{- define "px.hookServiceAccount" -}}
{{- if .Values.serviceAccount.hook.create -}}
    {{- printf "%s-hook" .Chart.Name | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- else -}}
    {{ default "default" .Values.serviceAccount.hook.name }}
{{- end -}}
{{- end -}}

{{/*
Create the name of the cluster role to use for hooks
*/}}
{{- define "px.hookClusterRole" -}}
{{- if .Values.serviceAccount.hook.create -}}
    {{- printf "%s-hook" .Chart.Name | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- else -}}
    {{ default "default" .Values.serviceAccount.hook.name }}
{{- end -}}
{{- end -}}

{{/*
Create the name of the cluster role binding to use for hooks
*/}}
{{- define "px.hookClusterRoleBinding" -}}
{{- if .Values.serviceAccount.hook.create -}}
    {{- printf "%s-hook" .Chart.Name | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- else -}}
    {{ default "default" .Values.serviceAccount.hook.name }}
{{- end -}}
{{- end -}}


{{/*
Create the name of the role to use for hooks
*/}}
{{- define "px.hookRole" -}}
{{- if .Values.serviceAccount.hook.create -}}
    {{- printf "%s-hook" .Chart.Name | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- else -}}
    {{ default "default" .Values.serviceAccount.hook.name }}
{{- end -}}
{{- end -}}

{{/*
Create the name of the role binding to use for hooks
*/}}
{{- define "px.hookRoleBinding" -}}
{{- if .Values.serviceAccount.hook.create -}}
    {{- printf "%s-hook" .Chart.Name | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- else -}}
    {{ default "default" .Values.serviceAccount.hook.name }}
{{- end -}}
{{- end -}}

{{/*
Generate a random token for storage provisioning
*/}}

{{- define "portworx-cluster-key" -}}
{{- randAlphaNum 16 | nospace | b64enc -}}
{{- end -}}


{{- define "px.affinityPxEnabledOperator" -}}
{{- if .Values.requirePxEnabledTag -}}
    {{- "In" }}
{{- else -}}
    {{ "NotIn" }}
{{- end -}}
{{- end -}}


{{- define "px.affinityPxEnabledValue" -}}
{{- if .Values.requirePxEnabledTag -}}
    {{- "true"  | quote }}
{{- else -}}
    {{ "false" | quote }}
{{- end -}}
{{- end -}}