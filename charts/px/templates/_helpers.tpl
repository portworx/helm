{{/* Gets the correct API Version based on the version of the cluster 
*/}}

{{- define "rbac.apiVersion" -}}
{{- if ge .Capabilities.KubeVersion.Minor "8" -}}
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