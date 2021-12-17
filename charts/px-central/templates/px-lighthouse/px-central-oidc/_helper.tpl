{{- define "keykloak.proxy" -}}
{{- if .Values.proxyHTTPEndpoint -}}
    {{- printf ";%s" .Values.proxyHTTPEndpoint -}}
{{- end -}}
{{- if .Values.proxyHTTPSEndpoint -}}
    {{- printf ";%s" .Values.proxyHTTPSEndpoint -}}
{{- end -}}
{{- end -}}