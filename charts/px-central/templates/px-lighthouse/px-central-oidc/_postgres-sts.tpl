{{/*-
px-central.keycloakPostgresStatefulSet renders the canonical Keycloak PostgreSQL
StatefulSet exactly once so it can be shared by the normal manifest and the
pre-upgrade target blueprint (PB-15738). Any change here must keep both
consumers in sync; unit coverage is via chart rendering tests.
*/}}
{{/*- px-central.keycloakPostgresMajor resolves the numeric PostgreSQL major from
the image catalog tag (single source of truth) so the hook never parses tags. */}}
{{- define "px-central.keycloakPostgresMajor" -}}
{{- $p := include "px.imageParts" (dict "key" "keycloakBackendImage" "root" .) | fromJson -}}
{{- first (splitList "." (toString $p.tag)) -}}
{{- end -}}
{{/*- px-central.keycloakPostgresClaimName follows the image major. */}}
{{- define "px-central.keycloakPostgresClaimName" -}}
pxcentral-keycloak-data-postgres{{ include "px-central.keycloakPostgresMajor" . }}
{{- end -}}
{{- define "px-central.keycloakPostgresStatefulSet" -}}
{{- $operatorToChartUpgrade := .Values.operatorToChartUpgrade | default false -}}
{{- $isOpenshiftCluster := or .Values.isOpenshift (.Capabilities.APIVersions.Has "apps.openshift.io/v1") -}}
{{- $azureProxyEnabled := .Values.proxy.azureProxyEnabled | default false -}}
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: pxcentral-keycloak-postgresql
  namespace: {{ .Release.Namespace }}
  labels:
    app: postgresql
    role: master
    app.kubernetes.io/component: keycloak
{{- include "px-central.labels" . | nindent 4 }}
spec:
  serviceName: pxcentral-keycloak-postgresql-headless
  replicas: 1
  updateStrategy:
    type: RollingUpdate
  selector:
    matchLabels:
      app: postgresql
      role: master
      app.kubernetes.io/component: keycloak
      app.kubernetes.io/name: {{.Release.Name }}
      app.kubernetes.io/instance: {{.Release.Name }}
      app.kubernetes.io/managed-by: {{.Release.Service }}
  template:
    metadata:
      name: pxcentral-keycloak-postgresql
      {{- if and (eq $azureProxyEnabled true) (not (has "pxcentral-keycloak-postgresql" .Values.proxy.excludeAzureProxyList)) }}
      annotations:
        kubernetes.azure.com/no-http-proxy-vars: "true"
      {{- end }}
      labels:
        app: postgresql
        role: master
        app.kubernetes.io/component: keycloak
        app.kubernetes.io/name: {{.Release.Name }}
        app.kubernetes.io/instance: {{.Release.Name }}
        app.kubernetes.io/managed-by: {{.Release.Service }}
{{- include "px-central.partOfLabel" . | nindent 8 }}
    spec:
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              {{- if .Values.nodeAffinityLabel }}
              - key: {{ .Values.nodeAffinityLabel }}
                operator: Exists
              {{- else }}
              - key: pxbackup/enabled
                operator: NotIn
                values:
                - "false"
              {{- end }}
      serviceAccountName: px-keycloak-account
      {{- if eq .Values.storkRequired true }}
      schedulerName: stork
      {{- end }}
      {{- if .Values.images.pullSecrets }}
      imagePullSecrets:
        {{- range $sec := .Values.images.pullSecrets }}
        - name: {{ $sec | quote }}
        {{- end }}
      {{- end }}
      {{- if $isOpenshiftCluster}}
      {{- else }}
      securityContext:
{{ toYaml .Values.securityContext | indent 8 }}
      {{- end }}
      containers:
        - name: pxcentral-keycloak-postgresql
          image: {{ include "px.image" (dict "key" "keycloakBackendImage" "root" .) }}
          imagePullPolicy: {{ .Values.images.pullPolicy }}
          {{ if eq $operatorToChartUpgrade true }}
          securityContext:
            runAsUser: 1001
          {{- end }}
          env:
            - name: BITNAMI_DEBUG
              value: "false"
          {{- include "serviceMesh.env" . | nindent 12 }}
            - name: POSTGRESQL_PORT_NUMBER
              value: "5432"
            - name: POSTGRESQL_VOLUME_DIR
              value: "/bitnami/postgresql"
            - name: PGDATA
              value: "/bitnami/postgresql/data"
            - name: POSTGRES_USER
              valueFrom:
                secretKeyRef:
                  name: pxcentral-keycloak-postgresql
                  key: postgresql-username
            - name: POSTGRES_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: pxcentral-keycloak-postgresql
                  key: postgresql-password
            - name: POSTGRES_DB
              value: "keycloak"
            - name: POSTGRESQL_ENABLE_LDAP
              value: "no"
            {{- if or (empty .Values.proxy.includeNoProxyList) (has "pxcentral-keycloak-postgresql" .Values.proxy.includeNoProxyList) }}
            {{- include "proxy.proxyEnv" . | nindent 12 }}
            {{- end }}
          ports:
            - name: tcp-postgresql
              containerPort: 5432
          livenessProbe:
            exec:
              command:
                - /bin/sh
                - -c
                - exec pg_isready -U "keycloak" -d "keycloak" -h 127.0.0.1 -p 5432
            initialDelaySeconds: 30
            periodSeconds: 10
            timeoutSeconds: 5
            successThreshold: 1
            failureThreshold: 6
          readinessProbe:
            exec:
              command:
                - /bin/sh
                - -c
                - -e
                - |
                  exec pg_isready -U "keycloak" -d "keycloak" -h 127.0.0.1 -p 5432
                  [ -f /opt/bitnami/postgresql/tmp/.initialized ] || [ -f /bitnami/postgresql/.initialized ]
            initialDelaySeconds: 5
            periodSeconds: 10
            timeoutSeconds: 5
            successThreshold: 1
            failureThreshold: 6
          volumeMounts:
            - name: dshm
              mountPath: /dev/shm
            - name: {{ include "px-central.keycloakPostgresClaimName" . }}
              mountPath: /bitnami/postgresql
          {{- if .Values.proxy.configSecretName }}
            - mountPath: /etc/ssl/certs/proxy-ca.pem
              subPath: proxy-ca.pem
              name: proxy-ca-volume
              readOnly: true
          {{- end }}
      {{- with .Values.tolerations }}
      tolerations:
      {{- toYaml . | nindent 8 }}
      {{- end }}
      volumes:
      {{- if .Values.proxy.configSecretName }}
        - name: proxy-ca-volume
          secret:
            items:
            - key: CA
              path: proxy-ca.pem
            optional: true
            secretName: {{ .Values.proxy.configSecretName }}
      {{- end }}
        - name: dshm
          emptyDir:
            medium: Memory
            sizeLimit: 1Gi
  volumeClaimTemplates:
    - metadata:
        name: {{ include "px-central.keycloakPostgresClaimName" . }}
      spec:
        accessModes:
          - "ReadWriteOnce"
        resources:
          requests:
            storage: {{ .Values.persistentStorage.keycloakBackendVolumeSize }}
        {{- if .Values.persistentStorage.storageClassName }}
        storageClassName: {{ .Values.persistentStorage.storageClassName }}
        {{- end }}
{{- end -}}
