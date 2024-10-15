{{- define "default.password" -}}
{{- $password := include "getOrGeneratePassword" . -}}
{{- $password -}}
{{- end -}}