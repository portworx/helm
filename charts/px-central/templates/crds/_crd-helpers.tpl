{{/*
=============================================================================
CRD Helper Templates for Helm 4 SSA Compatibility
=============================================================================

These helpers support conditional CRD installation to prevent conflicts when
CRDs are pre-installed by another component (e.g., Portworx Enterprise).

In Helm 4 with Server-Side Apply (SSA), CRD ownership conflicts occur when
multiple managers attempt to manage the same CRD. By conditionally installing
CRDs only when they don't exist, we avoid these conflicts.

SUPPORTED VALUES for .Values.installCRDs:
  - "true"  : Always install CRDs (use when CRDs don't exist)
  - "false" : Never install CRDs (use with ArgoCD when CRDs are managed separately,
              or when Portworx Enterprise is pre-installed)
  - "auto"  : Use Helm lookup to detect if CRDs exist (default)
              NOTE: With ArgoCD, lookup always returns empty, so "auto" behaves
              like "true". ArgoCD users with pre-existing CRDs should use "false".

ARGOCD USERS:
  When deploying via ArgoCD with pre-existing CRDs (e.g., Portworx installed),
  you MUST set installCRDs: "false" to avoid conflicts. ArgoCD uses `helm template`
  which doesn't have cluster access, so the lookup function cannot detect existing CRDs.

  Alternatively, use ArgoCD's built-in skipCrds option:
    spec:
      source:
        helm:
          skipCrds: true
*/}}

{{/*
Check if a CRD exists in the cluster.
Usage: {{ include "px-central.crdExists" "alertmanagers.monitoring.coreos.com" }}
Returns: "true" if the CRD exists, "false" otherwise

NOTE: This returns "false" when used with ArgoCD (helm template) because
      lookup requires cluster access which ArgoCD doesn't provide during rendering.
*/}}
{{- define "px-central.crdExists" -}}
{{- $crd := lookup "apiextensions.k8s.io/v1" "CustomResourceDefinition" "" . -}}
{{- if $crd }}true{{- else }}false{{- end -}}
{{- end -}}

{{/*
Determine if a CRD should be installed based on installCRDs value.
Usage: {{ include "px-central.shouldInstallCRD" (dict "crdName" "alertmanagers.monitoring.coreos.com" "context" .) }}
Returns: "true" if the CRD should be installed, "false" otherwise

Logic:
  - installCRDs: "true" or true   -> Always return "true"
  - installCRDs: "false" or false -> Always return "false"
  - installCRDs: "auto" (default) -> Use lookup to check if CRD exists
                                     (NOTE: ArgoCD will always get "true" here due to lookup limitations)

NOTE: Helm --set flag parses "false" as boolean, while values.yaml keeps it as string.
      This helper handles both boolean and string types.
*/}}
{{- define "px-central.shouldInstallCRD" -}}
{{- /* Get installCRDs value, defaulting to "auto" if nil/empty string */ -}}
{{- $installCRDs := .context.Values.installCRDs -}}
{{- /* Check if installCRDs is nil or empty string (but NOT boolean false) */ -}}
{{- $isNilOrEmpty := and (not (kindIs "bool" $installCRDs)) (not $installCRDs) -}}
{{- if $isNilOrEmpty -}}
{{- $installCRDs = "auto" -}}
{{- end -}}
{{- /* Convert to string for consistent comparison */ -}}
{{- $installCRDsStr := toString $installCRDs -}}
{{- /* Handle "true" (also handles boolean true which becomes "true") */ -}}
{{- if eq $installCRDsStr "true" -}}
true
{{- /* Handle "false" (also handles boolean false which becomes "false") */ -}}
{{- else if eq $installCRDsStr "false" -}}
false
{{- else -}}
{{- /* installCRDs = "auto" - use lookup */ -}}
{{- $crdExists := include "px-central.crdExists" .crdName -}}
{{- if eq $crdExists "true" -}}
false
{{- else -}}
true
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
CRD labels - common labels for all CRDs
*/}}
{{- define "px-central.crdLabels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/part-of: px-central
helm.sh/chart: {{ include "px-central.chart" . }}
{{- end -}}
