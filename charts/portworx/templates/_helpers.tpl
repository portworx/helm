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
        {{- if .Values.openshiftInstall -}}
            {{cat (trim .Values.customRegistryURL) "/portworx/stork" | replace " " ""}}
        {{- else -}}
            {{cat (trim .Values.customRegistryURL) "/openstorage/stork" | replace " " ""}}
        {{- end -}}
    {{- end -}}
{{- else -}}
    {{- if .Values.openshiftInstall -}}
        {{ "registry.connect.redhat.com/portworx/stork" }}
    {{- else -}}
        {{ "openstorage/stork" }}
    {{- end -}}
{{- end -}}
{{- end -}}

{{- define "px.getk8sSchedulerImage" -}}
{{- if (.Values.customRegistryURL) -}}
    {{- if (eq "/" (.Values.customRegistryURL | regexFind "/")) -}}
        {{ cat (trim .Values.customRegistryURL) "/kube-scheduler-amd64" | replace " " ""}}
    {{- else -}}
        {{cat (trim .Values.customRegistryURL) "/gcr.io/google_containers/kube-scheduler-amd64" | replace " " ""}}
    {{- end -}}
{{- else -}}
        {{ "gcr.io/google_containers/kube-scheduler-amd64" }}
{{- end -}}
{{- end -}}


{{- define "px.getk8sControllerImage" -}}
{{- if (.Values.customRegistryURL) -}}
    {{- if (eq "/" (.Values.customRegistryURL | regexFind "/")) -}}
        {{ cat (trim .Values.customRegistryURL) "/kube-controller-manager-amd64" | replace " " ""}}
    {{- else -}}
        {{cat (trim .Values.customRegistryURL) "/gcr.io/google_containers/kube-controller-manager-amd64" | replace " " ""}}
    {{- end -}}
{{- else -}}
        {{ "gcr.io/google_containers/kube-controller-manager-amd64" }}
{{- end -}}
{{- end -}}

{{- define "px.getcsiAttacher" -}}
{{- if (.Values.customRegistryURL) -}}
    {{- if (eq "/" (.Values.customRegistryURL | regexFind "/")) -}}
        {{ cat (trim .Values.customRegistryURL) "/csi-attacher" | replace " " ""}}
    {{- else -}}
        {{cat (trim .Values.customRegistryURL) "/quay.io/k8scsi/csi-attacher" | replace " " ""}}
    {{- end -}}
{{- else -}}
        {{ "quay.io/k8scsi/csi-attacher" }}
{{- end -}}
{{- end -}}

{{- define "px.getcsiProvisioner" -}}
{{- if (.Values.customRegistryURL) -}}
    {{- if (eq "/" (.Values.customRegistryURL | regexFind "/")) -}}
        {{ cat (trim .Values.customRegistryURL) "/csi-provisioner" | replace " " ""}}
    {{- else -}}
        {{cat (trim .Values.customRegistryURL) "/quay.io/k8scsi/csi-provisioner" | replace " " ""}}
    {{- end -}}
{{- else -}}
        {{ "quay.io/k8scsi/csi-provisioner" }}
{{- end -}}
{{- end -}}

{{- define "px.registryConfigType" -}}
{{- if semverCompare ">=1.9" .Capabilities.KubeVersion.GitVersion -}}
".dockerconfigjson"
{{- else -}}
".dockercfg"
{{- end -}}
{{- end -}}
