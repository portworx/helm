# PX-Monitor

PX-Central is a unified, multi-user, multi-cluster management interface. Using PX-Monitor, you can manage and monitor portworx cluster metrics.

### NOTE: `px-monitor` chart has an dependency of `px-backup` chart. For `px-monitor` chart install, give the same namespace where `px-backup` chart is running.

### Prerequisites:
- PX-Backup chart has to be deployed and all components should be in running state.
- Edit `privileged` scc using command : `oc edit scc privileged` and add following into `users` section : `- system:serviceaccount:<PX_BACKUP_NAMESPACE>:px-monitor` change the PX_BACKUP_NAMESPACE.

## Installing the Chart

To install the chart with the release name `px-monitor`:

Add portworx/px-monitor helm repository using command:
```console
$ helm repo add portworx http://charts.portworx.io/
```

Update helm repository:
```console
$ helm repo update
```

Search for portworx repo:
```console
$ helm search repo portworx
```
Output:
```console
NAME                            CHART VERSION       APP VERSION         DESCRIPTION                                       
portworx/portworx               1.0.0                                   A Helm chart for installing Portworx on Kuberne...
portworx/px-monitor             1.0.0               1.0.0               A Helm chart for installing PX-Monitor with PX-C...
```

Note:
- To fetch `PX_BACKUP_INTERNAL_OIDC_CLIENT_SECRET` use command: `kubectl get cm --namespace <RELEASE_NAMESPACE>  pxcentral-ui-configmap -o jsonpath={.data.OIDC_CLIENT_SECRET}`
OR
- To fetch `PX_BACKUP_INTERNAL_OIDC_CLIENT_SECRET` use command: `kubectl get secret --namespace <RELEASE_NAMESPACE>  pxc-backup-secret -o jsonpath={.data.OIDC_CLIENT_SECRET} | base64 --decode`

- To fetch `PX_BACKUP_UI_ENDPOINT`:
   - External IP of `px-backup-ui` service 
   - `px-backup-ui` ingress host or address

Helm 3:
```console
$ helm install px-monitor portworx/px-monitor --namespace px-backup --create-namespace --set installCRDs=true,pxmonitor.pxCentralEndpoint=<PX_BACKUP_UI_ENDPOINT>,pxmonitor.oidcClientSecret=<PX_BACKUP_INTERNAL_OIDC_CLIENT_SECRET>
```

Helm 2:
```console
$ helm install --name px-monitor portworx/px-monitor--namespace px-backup --set installCRDs=true,pxmonitor.pxCentralEndpoint=<PX_BACKUP_UI_ENDPOINT>,pxmonitor.oidcClientSecret=<PX_BACKUP_INTERNAL_OIDC_CLIENT_SECRET>
```

## Upgrading the Chart
```console
$ helm upgrade px-monitor portworx/px-monitor --namespace px-backup
```

## Uninstalling the Chart

- To uninstall/delete the `px-monitor` chart:

```console
$ helm delete px-monitor --namespace px-backup
```

## Configuration

The following table lists the configurable parameters of the PX-Monitor chart and their default values.

Parameter | Description | Default
--- | --- | ---
`pxmonitor` | PX Monitor deployment | ``
`pxmonitor.enabled` | PX-Central cluster enabled monitor component | `true`
`pxmonitor.pxCentralEndpoint` | PX-Central endpoint (LB endpoint of px-backup-ui service, ingress host) | ``
`pxmonitor.sslEnabled` | PX-Central UI is accessibe on https | `false`
`pxmonitor.oidcClientID` | PX-Central internal oidc client ID | `pxcentral`
`pxmonitor.oidcClientSecret` | PX-Central internal oidc client secret | ``
`pxmonitor.nodeAffinityLabel` | Label for node affinity for monitor component| `""`
`installCRDs` | Install metrics stack required crds | `false`
`storkRequired` | Scheduler name as stork | `false`
`clusterDomain` | Cluster domain | `cluster.local`
`cassandraUsername` | Cassandra cluster username | `cassandra`
`cassandraPassword` | Cassandra cluster password | `cassandra`
`persistentStorage` | Persistent storage for all px-central px-monitor components | `""`
`persistentStorage.enabled` | Enable persistent storage | `false`
`persistentStorage.storageClassName` | Provide storage class name which exists | `""`
`persistentStorage.cassandra.storage` | Cassandra volumes size | `50Gi`
`persistentStorage.grafana.storage` | Grafana volumes size | `20Gi`
`persistentStorage.consul.storage` | Consul volumes size | `8Gi`
`securityContext` | Security context for the pod | `{runAsUser: 1000, fsGroup: 1000, runAsNonRoot: true}`
`images` | PX monitor stack images | ``
`images.pullSecrets` | Image pull secret | `docregistry-secret`
`images.pullPolicy` | Image pull policy | `Always`


## Advanced Configuration

### Expose PX-Backup UI with metrics frontend(Grafana) on ingress:

- Edit the current px-backup-ui ingress and add grafana and cortex endpoints, complete ingress spec are as follows:

- Example - 1:
```
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  annotations:
    kubernetes.io/ingress.class: nginx
  name: px-backup-ui-ingress
  namespace: px-backup
spec:
  rules:
  - http:
      paths:
      - backend:
          serviceName: px-backup-ui
          servicePort: 80
        path: /
      - backend:
          serviceName: pxcentral-keycloak-http
          servicePort: 80
        path: /auth
      - backend:
          serviceName: pxcentral-grafana
          servicePort: 3000
        path: /grafana(/|$)(.*)
      - backend:
          serviceName: pxcentral-cortex-nginx
          servicePort: 80
        path: /cortex(/|$)(.*)
```

- Example - 2:

```
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  annotations:
    ingress.bluemix.net/redirect-to-https: "True"
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/x-forwarded-port: "443"
  name: px-backup-ui-ingress
  namespace: px-backup
spec:
  rules:
  - host: px-backup-ui.test-1.us-east.containers.appdomain.cloud
    http:
      paths:
      - backend:
          serviceName: px-backup-ui
          servicePort: 80
        path: /
      - backend:
          serviceName: pxcentral-keycloak-http
          servicePort: 80
        path: /auth
      - backend:
          serviceName: pxcentral-grafana
          servicePort: 3000
        path: /grafana(/|$)(.*)
      - backend:
          serviceName: pxcentral-cortex-nginx
          servicePort: 80
        path: /cortex(/|$)(.*)
  tls:
  - hosts:
    - px-backup-ui.test-1.us-east.containers.appdomain.cloud
    secretName: test
```
Note: Change the secret and hosts based on your configuration. Also, `secretName` -> `kubernetes TLS certificates secret` is required only when you want to terminate TLS on the host/domain.
- Some examples:
  - AKS: https://docs.microsoft.com/en-us/azure/aks/ingress-own-tls
  - EKS: https://aws.amazon.com/blogs/opensource/network-load-balancer-nginx-ingress-controller-eks/