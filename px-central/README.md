# PX-Backup

PX-Central is a unified, multi-user, multi-cluster management interface. Using PX-Backup, users can backup/restore Kubernetes clusters with PX-Backup.

## Installing the Chart

To install the chart with the release name `px-backup`:

Add portworx/px-backup helm repository using command:
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
NAME                    CHART VERSION   APP VERSION         DESCRIPTION                                       
portworx/portworx       1.0.0                               A Helm chart for installing Portworx on Kuberne...
portworx/px-backup      1.0.0           1.0.2               A Helm chart for installing PX-Backup with PX-C...
```

Helm 3:
```console
$ helm install px-backup portworx/px-backup --namespace px-backup --create-namespace
```

Helm 2:
```console
$ helm install --name px-backup portworx/px-backup --namespace px-backup
```

## Enabling/Disabling px-backup
PX-backup can now be disabled while installing px-central using helm chart version 1.2.2 onwards . It will be enabled by default. To disable PX-backup add the following to your helm install command
--set pxbackup.enabled=false .

To enable px-backup after installing px-central, Follow the upgrade steps mentioned below, but either change pxbackup.enabled parameter in the values.yaml to "true" or pass --set pxbackup.enabled=true to the helm upgrade command in Step 4 .

## Upgrade chart to latest version
1. helm repo update

2. helm get values --namespace px-backup px-backup -o yaml > values.yaml

3. Delete post install job: `kubectl delete job -npx-backup pxcentral-post-install-hook`

4. Run helm upgrade command:
```console
helm upgrade px-backup portworx/px-backup --namespace px-backup  -f values.yaml
```

## Uninstalling the Chart

1. To uninstall/delete the `px-backup` chart:

```console
$ helm delete px-backup --namespace px-backup
```

2. To cleanup secrets and pvc created by px-backup:

```console
$ kubectl delete ns px-backup
```

## Configuration

The following table lists the configurable parameters of the PX-Backup chart and their default values.

Parameter | Description | Default
--- | --- | ---
`persistentStorage` | Persistent storage for all px-central components | `""`
`persistentStorage.enabled` | Enable persistent storage | `false`
`persistentStorage.storageClassName` | Provide storage class name which exists | `""`
`persistentStorage.mysqlVolumeSize` | MySQL volume size | `"100Gi"`
`persistentStorage.etcdVolumeSize` | ETCD volume size | `"64Gi"`
`persistentStorage.keycloakThemeVolumeSize` | Keycloak frontend theme volume size | `"5Gi"`
`persistentStorage.keycloakBackendVolumeSize` | Keycloak backend volume size | `"10Gi"`
`storkRequired` | Scheduler name as stork | `false`
`pxcentralDBPassword` | PX-Central cluster store mysql database password | `Password1`
`caCertsSecretName` | Name of the Kubernetes Secret, which contains the CA Certificates. | `""`
`oidc` | Enable OIDC for PX-Central and PX-backup for RBAC | `""`
`oidc.centralOIDC` | PX-Central OIDC | `""`
`oidc.centralOIDC.enabled` | PX-Central OIDC | `true`
`oidc.centralOIDC.defaultUsername` | PX-Central OIDC username | `admin`
`oidc.centralOIDC.defaultPassword` | PX-Central OIDC admin user password | `admin`
`oidc.centralOIDC.defaultEmail` | PX-Central OIDC admin user email | `admin@portworx.com`
`oidc.centralOIDC.keyCloakBackendUserName` | Keycloak backend store username | `keycloak`
`oidc.centralOIDC.keyCloakBackendPassword` | Keycloak backend store password | `keycloak`
`oidc.centralOIDC.clientId` | PX-Central OIDC client id | `pxcentral`
`oidc.centralOIDC.updateAdminProfile` | Enable/Disable admin profile update action | `true`
`oidc.externalOIDC` | Enable external OIDC provider | `""`
`oidc.externalOIDC.enabled` | Enabled external OIDC provider | `false`
`oidc.externalOIDC.clientID` | External OIDC client ID | `""`
`oidc.externalOIDC.clientSecret` | External OIDC client secret | `""`
`oidc.externalOIDC.endpoint` | External OIDC endpoint | `""`
`images` | PX-Backup deployment images | `""`
`pxbackup.enabled` | Enabled PX-Backup | `true`
`pxbackup.orgName` | PX-Backup organization name | `default`
`pxbackup.nodeAffinityLabel` | Label for node affinity for px-central components| `""`
`securityContext` | Security context for the pod | `{runAsUser: 1000, fsGroup: 1000, runAsNonRoot: true}`
`images.pullSecrets` | Image pull secrets | `docregistry-secret`
`images.pullPolicy` | Image pull policy | `Always`
`images.pxcentralApiServerImage.registry` | API server image registry | `docker.io`
`images.pxcentralApiServerImage.repo` | API server image repo | `portworx`
`images.pxcentralApiServerImage.imageName` | API server image name | `pxcentral-onprem-api`
`images.pxcentralApiServerImage.tag` | API server image tag | `1.2.1`
`images.pxcentralFrontendImage.registry` | PX-Central frontend image registry | `docker.io`
`images.pxcentralFrontendImage.repo` | PX-Central frontend image repo | `portworx`
`images.pxcentralFrontendImage.imageName` | PX-Central frontend image name | `pxcentral-onprem-ui-frontend`
`images.pxcentralFrontendImage.tag` | PX-Central frontend image tag | `1.2.2`
`images.pxcentralBackendImage.registry` | PX-Central backend image registry | `docker.io`
`images.pxcentralBackendImage.repo` | PX-Central backend image repo | `portworx`
`images.pxcentralBackendImage.imageName` | PX-Central backend image name | `pxcentral-onprem-ui-backend`
`images.pxcentralBackendImage.tag` | PX-Central backend image tag | `1.2.2`
`images.pxcentralMiddlewareImage.registry` | PX-Central middleware image registry | `docker.io`
`images.pxcentralMiddlewareImage.repo` | PX-Central middleware image repo | `portworx`
`images.pxcentralMiddlewareImage.imageName` | PX-Central middleware image name | `pxcentral-onprem-ui-lhbackend`
`images.pxcentralMiddlewareImage.tag`| PX-Central middleware image tag | `1.2.2`
`images.pxBackupImage.registry` | PX-Backup image registry | `docker.io`
`images.pxBackupImage.repo` | PX-Backup image repo | `portworx`
`images.pxBackupImage.imageName` | PX-Backup image name | `px-backup`
`images.pxBackupImage.tag` | PX-Backup image tag | `1.2.2`
`images.postInstallSetupImage.registry` | PX-Backup post install setup image registry | `docker.io`
`images.postInstallSetupImage.repo` | PX-Backup post install setup image repo | `portworx`
`images.postInstallSetupImage.imageName` | PX-Backup post install setup image name | `pxcentral-onprem-post-setup`
`images.postInstallSetupImage.tag` | PX-Backup post install setup image tag | `1.2.2`
`images.etcdImage.registry` | PX-Backup etcd image registry | `docker.io`
`images.etcdImage.repo` | PX-Backup etcd image repo | `bitnami`
`images.etcdImage.imageName` | PX-Backup etcd image name | `etcd`
`images.etcdImage.tag` | PX-Backup etcd image tag | `3.4.13-debian-10-r22`
`images.keycloakBackendImage.registry` | PX-Backup keycloak backend image registry | `docker.io`
`images.keycloakBackendImage.repo` | PX-Backup keycloak backend image repo | `bitnami`
`images.keycloakBackendImage.imageName` | PX-Backup keycloak backend image name | `postgresql`
`images.keycloakBackendImage.tag` | PX-Backup keycloak backend image tag | `11.7.0-debian-10-r9`
`images.keycloakFrontendImage.registry` | PX-Backup keycloak frontend image registry | `docker.io`
`images.keycloakFrontendImage.repo` | PX-Backup keycloak frontend image repo | `jboss`
`images.keycloakFrontendImage.imageName` | PX-Backup keycloak frontend image name | `keycloak`
`images.keycloakFrontendImage.tag` | PX-Backup keycloak frontend image tag | `9.0.2`
`images.keycloakLoginThemeImage.registry` | PX-Backup keycloak login theme image registry | `docker.io`
`images.keycloakLoginThemeImage.repo` | PX-Backup keycloak login theme image repo | `portworx`
`images.keycloakLoginThemeImage.imageName` | PX-Backup keycloak login theme image name | `keycloak-login-theme`
`images.keycloakLoginThemeImage.tag` | PX-Backup keycloak login theme image tag | `1.0.4`
`images.keycloakInitContainerImage.registry` | PX-Backup keycloak init container image registry | `docker.io`
`images.keycloakInitContainerImage.repo` | PX-Backup keycloak init container image repo | `library`
`images.keycloakInitContainerImage.imageName` | PX-Backup keycloak init container image name | `busybox`
`images.keycloakInitContainerImage.tag` | PX-Backup keycloak init container image tag | `1.31`
`images.mysqlImage.registry` | PX-Central cluster store mysql image registry | `docker.io`
`images.mysqlImage.repo` | PX-Central cluster store mysql image repo | `library`
`images.mysqlImage.imageName` | PX-Central cluster store mysql image name | `mysql`
`images.mysqlImage.tag` | PX-Central cluster store mysql image tag | `5.7.22`

## Advanced Configuration

### Expose PX-Backup UI on ingress and access using https:

1. Create the following spec:
```
cat <<< ' 
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
  tls:
  - hosts:
    - px-backup-ui.test-1.us-east.containers.appdomain.cloud
    secretName: test
' > /tmp/px-backup-ui-ingress.yaml
```

Note: Change the secret and hosts based on your configuration. Also, `secretName` -> `kubernetes TLS certificates secret` is required only when you want to terminate TLS on the host/domain.
- Some examples:
  - AKS: https://docs.microsoft.com/en-us/azure/aks/ingress-own-tls
  - EKS: https://aws.amazon.com/blogs/opensource/network-load-balancer-nginx-ingress-controller-eks/

2. Apply the spec:
```console
$ kubectl apply -f /tmp/px-backup-ui-ingress.yaml
```

3. Retrieve the `INGRESS_ENDPOINT` using command:
```console
$ kubectl get ingress px-backup-ui-ingress --namespace px-backup -o jsonpath="{.status.loadBalancer.ingress[0].hostname}"
```

4. Access PX-Backup UI : `https://INGRESS_ENDPOINT` use default credentials (admin/admin) to login.

5. Access Keycloak UI: `https://INGRESS_ENDPOINT/auth`

### Access PX-Backup UI and Keycloak using node IP:
1. Get any node public/external IP (NODE_IP) of current k8s cluster.

2. Get the node port (NODE_PORT) of service: `px-backup-ui`.

3. PX-Backup UI is available at: `http://NODE_IP:NODE_PORT`

4. Keycloak UI is available at: `http://NODE_IP:NODE_PORT/auth`


### Access PX-Backup UI using Loadbalancer Endpoint:
1. Get the loadbalancer endpoint (LB_ENDPOINT) using following commands:
   - HOST: 
   ```console
   $ kubectl get ingress --namespace {{ .Release.Namespace }} px-backup-ui -o jsonpath="{.status.loadBalancer.ingress[0].hostname}"`
   ```
   - IP:
   ```console
   $ kubectl get ingress --namespace {{ .Release.Namespace }} px-backup-ui -o jsonpath="{.status.loadBalancer.ingress[0].ip}"`
   ```
  
2. PX-Backup UI endpoint: `http://LB_ENDPOINT`

3. Keycloak UI endpoint: `http://LB_ENDPOINT/auth`

### Configure custom ca certificate:
1. Create secret with ca certificates into release namespace.

Example:
```
apiVersion: v1
stringData:
  ca.crt: |
    -----BEGIN CERTIFICATE-----
    MIIEczCCA1ugAwIBAgIBADANBgkqhkiG9w0BAQQFAD..AkGA1UEBhMCR0Ix
    EzARBgNVBAgTClNvbWUtU3RhdGUxFDASBgNVBAoTC0..0EgTHRkMTcwNQYD
    VQQLEy5DbGFzcyAxIFB1YmxpYyBQcmltYXJ5IENlcn..XRpb24gQXV0aG9y
    aXR5MRQwEgYDVQQDEwtCZXN0IENBIEx0ZDAeFw0wMD..TUwMTZaFw0wMTAy
    MDQxOTUwMTZaMIGHMQswCQYDVQQGEwJHQjETMBEGA1..29tZS1TdGF0ZTEU
    MBIGA1UEChMLQmVzdCBDQSBMdGQxNzA1BgNVBAsTLk..DEgUHVibGljIFBy
    aW1hcnkgQ2VydGlmaWNhdGlvbiBBdXRob3JpdHkxFD..AMTC0Jlc3QgQ0Eg
    THRkMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCg..Tz2mr7SZiAMfQyu
    vBjM9OiJjRazXBZ1BjP5CE/Wm/Rr500PRK+Lh9x5eJ../ANBE0sTK0ZsDGM
    ak2m1g7oruI3dY3VHqIxFTz0Ta1d+NAjwnLe4nOb7/..k05ShhBrJGBKKxb
    8n104o/5p8HAsZPdzbFMIyNjJzBM2o5y5A13wiLitE..fyYkQzaxCw0Awzl
    kVHiIyCuaF4wj571pSzkv6sv+4IDMbT/XpCo8L6wTa..sh+etLD6FtTjYbb
    rvZ8RQM1tlKdoMHg2qxraAV++HNBYmNWs0duEdjUbJ..XI9TtnS4o1Ckj7P
    OfljiQIDAQABo4HnMIHkMB0GA1UdDgQWBBQ8urMCRL..5AkIp9NJHJw5TCB
    tAYDVR0jBIGsMIGpgBQ8urMCRLYYMHUKU5AkIp9NJH..aSBijCBhzELMAkG
    A1UEBhMCR0IxEzARBgNVBAgTClNvbWUtU3RhdGUxFD..AoTC0Jlc3QgQ0Eg
    THRkMTcwNQYDVQQLEy5DbGFzcyAxIFB1YmxpYyBQcm..ENlcnRpZmljYXRp
    b24gQXV0aG9yaXR5MRQwEgYDVQQDEwtCZXN0IENBIE..DAMBgNVHRMEBTAD
    AQH/MA0GCSqGSIb3DQEBBAUAA4IBAQC1uYBcsSncwA..DCsQer772C2ucpX
    xQUE/C0pWWm6gDkwd5D0DSMDJRqV/weoZ4wC6B73f5..bLhGYHaXJeSD6Kr
    XcoOwLdSaGmJYslLKZB3ZIDEp0wYTGhgteb6JFiTtn..sf2xdrYfPCiIB7g
    BMAV7Gzdc4VspS6ljrAhbiiawdBiQlQmsBeFz9JkF4..b3l8BoGN+qMa56Y
    It8una2gY4l2O//on88r5IWJlm1L0oA8e4fR2yrBHX..adsGeFKkyNrwGi/
    7vQMfXdGsRrXNGRGnX+vWDZ3/zWI0joDtCkNnqEpVn..HoX
    -----END CERTIFICATE-----
kind: Secret
metadata:
  name: ca-certs
  namespace: px-backup
```

2. Pass the secret name to chart using flag: `--set caCertsSecretName=<SECRET_NAME>`

### Expose PX-Backup UI on openshift routes and access using http and https:
1. Create single route with hostname and path: `/` and point it to `px-backup-ui` service. 
2. Access PX-Backup UI using route endpoint.
Note: Keycloak auth and Grafana UI will be accessible on same endpoint on different paths: `/auth` and `/grafana`.

## FAQ

1. How to check install logs:
   To get the logs of post install hook:
   ```console
   $ kubectl logs -f --namespace {{ .Release.Namespace }} -ljob-name=pxcentral-post-install-hook
   ```

2. If one or many pods of the etcd replica goes into `CrashLoopBackOff` state during install or upgrade and error looks like following:
```
pxc-backup-etcd-1                          0/1     CrashLoopBackOff   6          10m
[root@ip-node1 helm]# kubectl logs pxc-backup-etcd-1 -n px-backup
==> Bash debug is off
==> Detected data from previous deployments...
==> Adding new member to existing cluster...
```

then, to resolve this issue scale down etcd cluster to 0 and scale it back to 3.
- To scale down etcd cluster to 0:
```console
$ kubectl scale sts --namespace px-backup pxc-backup-etcd --replicas=0`
```

- To scale up etcd cluster to 3:
```console
$ kubectl scale sts --namespace px-backup pxc-backup-etcd --replicas=3`
```


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



  # PX-License-Server

PX-Central is a unified, multi-user, multi-cluster management interface. Using PX-License-Server, you can manage license for all your portworx clusters.

### NOTE: `px-license-server` chart has an dependency of `px-backup` chart. For `px-license-server` chart install, give the same namespace where `px-backup` chart is running.

### Prerequisites:
- PX-Backup chart has to be deployed and all components should be in running state.
- Set `px/ls=true` label to any of two worker nodes.
```console
$ kubectl label node <NODE_NAME> px/ls=true
```
- For openshift cluster:
1. Edit `privileged` scc using command : `oc edit scc privileged` and add following into `users` section : `- system:serviceaccount:<PX_BACKUP_NAMESPACE>:pxcentral-license-server` change the PX_BACKUP_NAMESPACE.
2. Enable SSH access on port 7070, To configure same add following into worker nodes where `px/ls=true` label is set: 
   - `-A INPUT -p tcp -m state --state NEW -m tcp --dport 7070 -j ACCEPT` in `/etc/sysconfig/iptables` file
   - Restart iptables service: `systemctl restart iptables.service`

## Installing the Chart

To install the chart with the release name `px-license-server`:

Add portworx/px-license-server helm repository using command:
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
portworx/px-license-server      1.0.0               1.0.0               A Helm chart for installing PX-License-Server with PX-C...
```

Helm 3:
```console
$ helm install px-license-server portworx/px-license-server --namespace px-backup --create-namespace
```

Helm 2:
```console
$ helm install --name px-license-server portworx/px-license-server --namespace px-backup
```

## Upgrading the Chart
```console
$ helm upgrade px-license-server portworx/px-license-server --namespace px-backup
```

## Uninstalling the Chart

- To uninstall/delete the `px-license-server` chart:

```console
$ helm delete px-license-server --namespace px-backup
```

## Configuration

The following table lists the configurable parameters of the PX-License-Server chart and their default values.

Parameter | Description | Default
--- | --- | ---
`pxlicenseserver` | PX license server deployment | ``
`pxlicenseserver.internal` | PX-Central cluster license server | ``
`pxlicenseserver.internal.enabled` | PX-Central cluster license server enabled | `true`
`pxlicenseserver.internal.lsTypeUAT` | PX license server deployment type [UAT] | `false`
`pxlicenseserver.internal.lsTypeAirgapped` | PX license server deployment type [Air-gapped] | `false`
`pxlicenseserver.external.enabled` | External license server enabled | `false`
`pxlicenseserver.mainNodeIP` | External license server main node endpoints | ``
`pxlicenseserver.backupNodeIP` | External license server backup node endpoints | ``
`pxlicenseserver.adminUserName` | PX license server admin user name | `admin`
`pxlicenseserver.adminUserPassword` | PX license server admin user password | `Password@1`
`securityContext` | Security context for the pod | `{runAsUser: 1000, fsGroup: 1000, runAsNonRoot: true}`
`images` | PX license server images | ``
`images.pullSecrets` | Image pull secret | `km`
`images.pullPolicy` | Image pull policy | `Always`
`images.licenseServerImage` | License server images | ``
`images.licenseServerImage.registry` | License server image registry | `docker.io`
`images.licenseServerImage.repo` | License server image repo | `portworx`
`images.licenseServerImage.imageName` | License server image name | `px-els`
`images.licenseServerImage.tag` | License server image tag | `1.0.0`
`images.pxLicenseHAConfigContainerImage` | License server HA configuration image | ``
`images.pxLicenseHAConfigContainerImage.registry` | License server HA configuration image registry | `docker.io`
`images.pxLicenseHAConfigContainerImage.repo` | License server HA configuration image repo | `portworx`
`images.pxLicenseHAConfigContainerImage.imageName` | License server HA configuration image name | `pxcentral-onprem-els-ha-setup`
`images.pxLicenseHAConfigContainerImage.tag` | License server HA configuration image tag | `1.0.2`
