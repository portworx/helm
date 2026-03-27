{{- define "portworx-operator" -}}
{{- if and .Namespace (ne .Namespace "kube-system") -}}
apiVersion: v1
kind: Namespace
metadata:
  name: "{{.Namespace}}"
---
{{- end}}
apiVersion: v1
kind: ServiceAccount
metadata:
  {{- if .AnthosCR}}
  annotations:
    configmanagement.gke.io/cluster-selector: "{{.AnthosCR}}"
  {{- end}}
  name: portworx-operator
  namespace: {{.Namespace}}
---
{{- if .UsePodSecurityPolicies}}
apiVersion: policy/v1beta1
kind: PodSecurityPolicy
metadata:
  name: px-operator
  {{- if .AnthosCR}}
  annotations:
    configmanagement.gke.io/cluster-selector: "{{.AnthosCR}}"
  {{- end}}
spec:
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: false
  volumes:
  - secret
  runAsUser:
    rule: 'RunAsAny'
  seLinux:
    rule: 'RunAsAny'
  supplementalGroups:
    rule: 'RunAsAny'
  fsGroup:
    rule: 'RunAsAny'
---
{{- end}}
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  {{- if .AnthosCR}}
  annotations:
    configmanagement.gke.io/cluster-selector: "{{.AnthosCR}}"
  {{- end}}
  name: portworx-operator
rules:
  {{- if .RestrictDataProtectionRBAC}}
  # Tier-0 Operator ClusterRole 
  # This ClusterRole has minimum permissions for the operator to function
  # but does NOT have wildcard permissions (*/*/*)
  # Includes: KubeVirt, CDI, Clone, Migrations, Snapshots for VM support
  # Tier-0 Operator ClusterRole (48 rules)
  # This ClusterRole has minimum permissions for the operator to function
  # but does NOT have wildcard permissions (*/*/*)
  # Includes: KubeVirt, CDI, Clone, Migrations, Snapshots for VM support
  # 1. Pods
  - apiGroups: [""]
    resources: ["pods", "pods/status", "pods/log", "pods/exec"]
    verbs: ["get", "list", "watch", "create", "delete", "update", "patch"]
  # 2. Events (core)
  - apiGroups: [""]
    resources: ["events"]
    verbs: ["get", "list", "watch", "create", "update", "patch"]
  # 3. Events (events.k8s.io)
  - apiGroups: ["events.k8s.io"]
    resources: ["events"]
    verbs: ["get", "list", "watch", "create", "update", "patch"]
  # 4. Nodes - includes nodes/metrics for Prometheus
  - apiGroups: [""]
    resources: ["nodes", "nodes/status", "nodes/metrics"]
    verbs: ["get", "list", "watch", "update", "patch"]
  # 5. Namespaces
  - apiGroups: [""]
    resources: ["namespaces"]
    verbs: ["get", "list", "watch"]
  # 6. ConfigMaps - wildcard for Prometheus
  - apiGroups: [""]
    resources: ["configmaps"]
    verbs: ["*"]
  # 7. Secrets - wildcard for Prometheus
  - apiGroups: [""]
    resources: ["secrets"]
    verbs: ["*"]
  # 8. Services, Endpoints - includes services/finalizers for Prometheus
  - apiGroups: [""]
    resources: ["services", "services/finalizers", "endpoints"]
    verbs: ["get", "list", "watch", "create", "delete", "update", "patch"]
  # 9. kube-scheduler endpoint (for Stork scheduler leader election)
  - apiGroups: [""]
    resources: ["endpoints"]
    resourceNames: ["kube-scheduler"]
    verbs: ["get", "delete", "update", "patch"]
  # 10. ServiceAccounts (including token subresource)
  - apiGroups: [""]
    resources: ["serviceaccounts", "serviceaccounts/token"]
    verbs: ["get", "list", "watch", "create", "delete", "update"]
  # 11. PersistentVolumes - added patch verb for CSI
  - apiGroups: [""]
    resources: ["persistentvolumes", "persistentvolumes/status"]
    verbs: ["get", "list", "create", "delete", "update", "watch", "patch"]
  # 12. PersistentVolumeClaims - added create, delete, patch for portworx and CSI
  - apiGroups: [""]
    resources: ["persistentvolumeclaims", "persistentvolumeclaims/status"]
    verbs: ["get", "list", "watch", "create", "delete", "update", "patch"]
  # 13. Apps resources - wildcard verbs for Prometheus operator
  - apiGroups: ["apps"]
    resources: ["controllerrevisions", "deployments", "replicasets", "daemonsets", "statefulsets"]
    verbs: ["*"]
  # 14. Extensions replicasets (backwards compatibility for Stork scheduler) + thirdpartyresources for Prometheus
  - apiGroups: ["extensions"]
    resources: ["replicasets", "thirdpartyresources"]
    verbs: ["*"]
  # 15. Storage resources - added volumeattributesclasses and patch verb
  - apiGroups: ["storage.k8s.io"]
    resources: ["storageclasses", "csinodes", "csidrivers", "csistoragecapacities", "volumeattachments", "volumeattributesclasses"]
    verbs: ["get", "list", "watch", "create", "delete", "update", "patch"]
  # 16. RBAC resources
  - apiGroups: ["rbac.authorization.k8s.io"]
    resources: ["roles", "rolebindings", "clusterroles", "clusterrolebindings"]
    verbs: ["get", "list", "watch", "create", "delete", "update", "patch"]
  # 17. Coordination (leases) - wildcard for PVC controller
  - apiGroups: ["coordination.k8s.io"]
    resources: ["leases"]
    verbs: ["*"]
  # 18. CRDs - wildcard for Prometheus operator
  - apiGroups: ["apiextensions.k8s.io"]
    resources: ["customresourcedefinitions"]
    verbs: ["*"]
  # 19. StorageCluster CRDs - Full access to core.libopenstorage.org
  - apiGroups: ["core.libopenstorage.org"]
    resources: ["*"]
    verbs: ["*"]
  # 20. StorageNode NodeDrain
  - apiGroups: ["storagenode.io"]
    resources: ["nodedrains"]
    verbs: ["get", "list", "watch", "create", "delete", "update", "patch"]
  # 21. Portworx resources
  - apiGroups: ["portworx.io"]
    resources: ["portworxdiags", "portworxdiags/status", "volumeplacementstrategies"]
    verbs: ["get", "list", "watch", "create", "delete", "update", "patch"]
  # 22. Monitoring (Prometheus) - wildcard for Prometheus operator
  - apiGroups: ["monitoring.coreos.com"]
    resources: ["servicemonitors", "prometheuses", "prometheuses/status", "prometheuses/finalizers", "prometheusrules", "alertmanagers", "alertmanagers/status", "alertmanagers/finalizers", "alertmanagerconfigs", "thanosrulers", "thanosrulers/finalizers", "podmonitors", "probes"]
    verbs: ["*"]
  # 23. Policy (PDB and PSP)
  - apiGroups: ["policy"]
    resources: ["poddisruptionbudgets", "podsecuritypolicies"]
    verbs: ["get", "list", "watch", "create", "delete", "update", "use"]
  # 24. Admissionregistration (webhooks)
  - apiGroups: ["admissionregistration.k8s.io"]
    resources: ["validatingwebhookconfigurations", "mutatingwebhookconfigurations"]
    verbs: ["get", "list", "watch", "create", "delete", "update", "patch"]
  # 25. Certificates
  - apiGroups: ["certificates.k8s.io"]
    resources: ["certificatesigningrequests", "certificatesigningrequests/approval", "certificatesigningrequests/status"]
    verbs: ["get", "list", "watch", "create", "delete", "update", "patch"]
  # 26. Certificate signers
  - apiGroups: ["certificates.k8s.io"]
    resources: ["signers"]
    resourceNames: ["kubernetes.io/legacy-unknown"]
    verbs: ["approve"]
  # 27. Scheduling (priority classes)
  - apiGroups: ["scheduling.k8s.io"]
    resources: ["priorityclasses"]
    verbs: ["get", "list", "watch", "create", "delete", "update"]
  # 28. Batch (jobs)
  - apiGroups: ["batch"]
    resources: ["jobs", "cronjobs"]
    verbs: ["get", "list", "watch", "create", "delete", "update", "patch"]
  # 29. OpenShift security
  - apiGroups: ["security.openshift.io"]
    resources: ["securitycontextconstraints"]
    verbs: ["get", "list", "watch", "create", "delete", "update", "use"]
  # 30. Cert-manager (KVDB TLS)
  - apiGroups: ["cert-manager.io"]
    resources: ["issuers", "issuers/status", "clusterissuers", "clusterissuers/status", "certificates", "certificates/status", "certificaterequests", "certificaterequests/status", "certificates/finalizers", "certificaterequests/finalizers"]
    verbs: ["get", "list", "watch", "create", "delete", "deletecollection", "update", "patch"]
  # 31. ACME Orders and Challenges (for cert-manager-controller-certificates, cert-manager-controller-orders, and cert-manager-controller-challenges)
  - apiGroups: ["acme.cert-manager.io"]
    resources: ["orders", "orders/status", "orders/finalizers", "challenges", "challenges/status", "challenges/finalizers"]
    verbs: ["create", "delete", "deletecollection", "get", "list", "watch", "update", "patch"]
  # 32. Networking for ACME challenges (HTTP01 and DNS01) and ingress-shim
  - apiGroups: ["networking.k8s.io"]
    resources: ["ingresses", "ingresses/finalizers"]
    verbs: ["create", "delete", "get", "list", "watch", "update"]
  - apiGroups: ["gateway.networking.k8s.io"]
    resources: ["httproutes", "httproutes/finalizers", "gateways", "gateways/finalizers"]
    verbs: ["create", "delete", "get", "list", "watch", "update"]
  - apiGroups: ["route.openshift.io"]
    resources: ["routes/custom-host"]
    verbs: ["create"]
  # 33. Pods and Services for ACME challenges
  - apiGroups: [""]
    resources: ["pods", "services"]
    verbs: ["create", "delete", "get", "list", "watch"]
  # 34. Signers for cert-manager approval
  - apiGroups: ["cert-manager.io"]
    resources: ["signers"]
    resourceNames: ["issuers.cert-manager.io/*", "clusterissuers.cert-manager.io/*"]
    verbs: ["approve"]
  # 35. Certificate signing requests and subject access reviews
  - apiGroups: ["certificates.k8s.io"]
    resources: ["signers"]
    resourceNames: ["issuers.cert-manager.io/*", "clusterissuers.cert-manager.io/*"]
    verbs: ["sign"]
  - apiGroups: ["authorization.k8s.io"]
    resources: ["subjectaccessreviews"]
    verbs: ["create"]
  # 36. API Registration (for cert-manager-cainjector to manage APIServices)
  - apiGroups: ["apiregistration.k8s.io"]
    resources: ["apiservices"]
    verbs: ["get", "list", "watch", "update", "patch"]
  # --- Additional permissions needed for Stork scheduler functionality
  # These are required so the operator can grant them to Stork's ClusterRole
  # 37. Bindings (for scheduler)
  - apiGroups: [""]
    resources: ["bindings", "pods/binding"]
    verbs: ["create"]
  # 38. ReplicationControllers (for scheduler)
  - apiGroups: [""]
    resources: ["replicationcontrollers"]
    verbs: ["get", "list", "watch"]
  # 39. Snapshot resources - added patch and status subresources for CSI
  - apiGroups: ["snapshot.storage.k8s.io"]
    resources: ["volumesnapshotclasses", "volumesnapshots", "volumesnapshotcontents", "volumesnapshots/status", "volumesnapshotcontents/status"]
    verbs: ["get", "list", "watch", "create", "delete", "update", "patch"]
  # 40. KubeVirt permissions - full access for portworx DaemonSet ClusterRole
  - apiGroups: ["kubevirt.io"]
    resources: ["*"]
    verbs: ["get", "list", "watch"]
  # 41. KubeVirt VM migrations
  - apiGroups: ["kubevirt.io"]
    resources: ["virtualmachineinstancemigrations"]
    verbs: ["get", "list", "create", "watch", "delete", "update"]
  # 42. CDI (Containerized Data Importer)
  - apiGroups: ["cdi.kubevirt.io"]
    resources: ["*"]
    verbs: ["get", "list", "watch"]
  # 43. Clone KubeVirt
  - apiGroups: ["clone.kubevirt.io"]
    resources: ["*"]
    verbs: ["get", "list", "watch"]
  # 44. Migrations KubeVirt
  - apiGroups: ["migrations.kubevirt.io"]
    resources: ["*"]
    verbs: ["get", "list", "watch"]
  # 45. Snapshot KubeVirt
  - apiGroups: ["snapshot.kubevirt.io"]
    resources: ["*"]
    verbs: ["get", "list", "watch"]
  # --- Additional permissions for Tier-0 Stork RBAC on libopenstorage.org CRs ---
  # 46. stork.libopenstorage.org - Full CRUD (required for operator to grant to Stork)
  - apiGroups: ["stork.libopenstorage.org"]
    resources: ["*"]
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
  # 47. autopilot.libopenstorage.org - Full access (required for operator to grant to Stork)
  - apiGroups: ["autopilot.libopenstorage.org"]
    resources: ["*"]
    verbs: ["*"]
  # 48. volumesnapshot.external-storage.k8s.io - Full CRUD (required for operator to grant to Stork)
  - apiGroups: ["volumesnapshot.external-storage.k8s.io"]
    resources: ["volumesnapshots", "volumesnapshotdatas"]
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
  # 49. kdmp.portworx.com - Full CRUD (required for operator to grant to Stork)
  - apiGroups: ["kdmp.portworx.com"]
    resources: ["*"]
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
  # 50. Networking (ingresses) for Prometheus
  - apiGroups: ["networking.k8s.io"]
    resources: ["ingresses"]
    verbs: ["get", "list", "watch"]
  # 51. Non-resource URLs for Prometheus metrics
  - nonResourceURLs: ["/metrics", "/metrics/cadvisor", "/federate"]
    verbs: ["get"]
  # 52. Resource API (K8s 1.26+ Dynamic Resource Allocation) - for stork-scheduler
  - apiGroups: ["resource.k8s.io"]
    resources: ["deviceclasses", "resourceclaims", "resourceslices"]
    verbs: ["get", "list", "watch"]
  # 53. CSI storage API - for px-csi driver management
  - apiGroups: ["csi.storage.k8s.io"]
    resources: ["csidrivers"]
    verbs: ["get", "list", "watch", "create", "delete"]
  # 54. OpenShift machine config (optional - for OCP clusters)
  - apiGroups: ["machineconfiguration.openshift.io"]
    resources: ["machineconfigpools"]
    verbs: ["get", "list", "watch"]
  # 55. SCC "anyuid" for px-prometheus-operator ClusterRole creation
  - apiGroups: ["security.openshift.io"]
    resources: ["securitycontextconstraints"]
    resourceNames: ["anyuid"]
    verbs: ["use"]
  # 56. PSP "px-restricted" for px-prometheus and px-prometheus-operator ClusterRole creation
  - apiGroups: ["policy"]
    resources: ["podsecuritypolicies"]
    resourceNames: ["px-restricted"]
    verbs: ["use"]
  {{- else}}
  - apiGroups: ["*"]
    resources: ["*"]
    verbs: ["*"]
  {{- end}}

  {{- if .UsePodSecurityPolicies}}
  - apiGroups: ["policy"]
    resources: ["podsecuritypolicies"]
    resourceNames: ["px-operator"]
    verbs: ["use"]
  {{- end}}
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  {{- if .AnthosCR}}
  annotations:
    configmanagement.gke.io/cluster-selector: "{{.AnthosCR}}"
  {{- end}}
  name: portworx-operator
subjects:
- kind: ServiceAccount
  name: portworx-operator
  namespace: {{.Namespace}}
roleRef:
  kind: ClusterRole
  name: portworx-operator
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: apps/v1
kind: Deployment
metadata:
  {{- if .AnthosCR}}
  annotations:
    configmanagement.gke.io/cluster-selector: "{{.AnthosCR}}"
  {{- end}}
  name: portworx-operator
  namespace: {{.Namespace}}
spec:
  strategy:
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 1
    type: RollingUpdate
  replicas: 1
  selector:
    matchLabels:
      name: portworx-operator
  template:
    metadata:
      labels:
        name: portworx-operator
    spec:
      containers:
      - name: portworx-operator
        imagePullPolicy: {{.PullPolicy}}
        image: {{.GetImageURN .PortworxOperatorImage}}
        command:
        - /operator
        - --verbose
        - --driver=portworx
        - --leader-elect=true
        env:
        - name: OPERATOR_NAME
          value: portworx-operator
        - name: POD_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
      {{- if .RegSecret}}
      imagePullSecrets:
        - name: "{{.RegSecret}}"
      {{- end}}
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            - labelSelector:
                matchExpressions:
                  - key: "name"
                    operator: In
                    values:
                    - portworx-operator
              topologyKey: "kubernetes.io/hostname"
      serviceAccountName: portworx-operator
{{- end}}
