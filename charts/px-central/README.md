# PX-Central
PX-Central is a unified, multi-user, multi-cluster management interface.
This chart also supports following features but by default those are disabled.
  1. PX-Backup
  2. PX-Monitor
  3. PX-License-Server

To enable each feature, follow the respective sections for detailed steps.

## Installing the Chart

To install the chart with the release name `px-central`:

Add portworx/px-central helm repository using command:
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
portworx/px-central     2.0.0        	  2.0.0      	    A Helm chart for installing PX-Central
```

Helm 3:
```console
$ helm install px-central portworx/px-central --namespace central --create-namespace
```

Helm 2:
```console
$ helm install --name px-central portworx/px-central --namespace central
```

## Uninstalling the Chart

1. To uninstall/delete the `px-central` chart:

```console
$ helm delete px-central --namespace central
```

2. To cleanup secrets and pvc:

```console
$ kubectl delete ns central
```

## Upgrading the Chart

  ### To Upgrade from >= 2.0.0 versions:
  To upgrade px-central:

  1. helm repo update
  
  2. helm get values --namespace central px-central -o yaml > values.yaml

  3. Delete post install job: `kubectl delete job -n central pxcentral-post-install-hook`

  4. Run following helm upgrade command to upgrade px-central chart

  Helm 3:
  ```console
  $ helm upgrade px-central portworx/px-central --namespace central -f values.yaml
  ```

  Helm 2:
  ```console
  $ helm upgrade --name px-central portworx/px-central --namespace central -f values.yaml
  ```

  ### To Upgrade from 1.2.X versions:
  In 1.2.x and previous versions , there are three charts (px-backup, px-monitor, px-license-server) which got merged into one chart(px-central)

  To upgrade from 1.2.x versions, please follow the steps mentioned [here](https://github.com/portworx/helm/blob/master/single_chart_migration/README.md)

## Advanced Configuration

### Expose PX-Central UI on ingress and access using https:

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
  name: px-central-ui-ingress
  namespace: central
spec:
  rules:
  - host: px-central-ui.test-1.us-east.containers.appdomain.cloud
    http:
      paths:
      - backend:
          serviceName: px-central-ui
          servicePort: 80
        path: /
      - backend:
          serviceName: pxcentral-keycloak-http
          servicePort: 80
        path: /auth
  tls:
  - hosts:
    - px-central-ui.test-1.us-east.containers.appdomain.cloud
    secretName: test
' > /tmp/px-central-ui-ingress.yaml
```

Note: Change the secret and hosts based on your configuration. Also, `secretName` -> `kubernetes TLS certificates secret` is required only when you want to terminate TLS on the host/domain.
- Some examples:
  - AKS: https://docs.microsoft.com/en-us/azure/aks/ingress-own-tls
  - EKS: https://aws.amazon.com/blogs/opensource/network-load-balancer-nginx-ingress-controller-eks/

2. Apply the spec:
```console
$ kubectl apply -f /tmp/px-central-ui-ingress.yaml
```

3. Retrieve the `INGRESS_ENDPOINT` using command:
```console
$ kubectl get ingress px-central-ui-ingress --namespace central -o jsonpath="{.status.loadBalancer.ingress[0].hostname}"
```

4. Access PX-Central UI : `https://INGRESS_ENDPOINT` use default credentials (admin/admin) to login.

5. Access Keycloak UI: `https://INGRESS_ENDPOINT/auth`

### Access PX-Central UI and Keycloak using node IP:
1. Get any node public/external IP (NODE_IP) of current k8s cluster.

2. Get the node port (NODE_PORT) of service: `px-central-ui`.

3. PX-Central UI is available at: `http://NODE_IP:NODE_PORT`

4. Keycloak UI is available at: `http://NODE_IP:NODE_PORT/auth`

### Access PX-Central UI using Loadbalancer Endpoint:
1. Get the loadbalancer endpoint (LB_ENDPOINT) using following commands:
   - HOST: 
   ```console
   $ kubectl get ingress --namespace {{ .Release.Namespace }} px-central-ui -o jsonpath="{.status.loadBalancer.ingress[0].hostname}"`
   ```
   - IP:
   ```console
   $ kubectl get ingress --namespace {{ .Release.Namespace }} px-central-ui -o jsonpath="{.status.loadBalancer.ingress[0].ip}"`
   ```
  
2. PX-Central UI endpoint: `http://LB_ENDPOINT`

3. Keycloak UI endpoint: `http://LB_ENDPOINT/auth`


# PX-Backup

Using PX-Backup, users can backup/restore Kubernetes clusters.
By default px-backup remains disabled with px-central installation.

## Enabling PX-Backup

  ### To enable PX-Backup along with px-central installation:

  Helm 3:
  ```console
  $ helm install px-central portworx/px-central --namespace central --create-namespace --set pxbackup.enabled=true
  ```

  Helm 2:
  ```console
  $ helm install --name px-central portworx/px-central --namespace central --set pxbackup.enabled=true
  ```

  ### To enable PX-Backup on already deployed px-central:

  1. helm get values --namespace central px-central -o yaml > values.yaml

  2. Delete post install job: `kubectl delete job -n central pxcentral-post-install-hook`

  3. Run following helm upgrade command to enable px-backup for same px-central chart

  Helm 3:
  ```console
  $ helm upgrade px-central portworx/px-central --namespace central --set pxbackup.enabled=true
  ```

  Helm 2:
  ```console
  $ helm upgrade --name px-central portworx/px-central --namespace central --set pxbackup.enabled=true
  ```

## Disabling PX-Backup

1. helm get values --namespace central px-central -o yaml > values.yaml

2. Delete post install job: `kubectl delete job -n central pxcentral-post-install-hook`

3. Run following helm upgrade command to disable px-backup for same px-central chart

To disable PX-Backup:

Helm 3:
```console
$ helm upgrade px-central portworx/px-central --namespace central --set pxbackup.enabled=false
```

Helm 2:
```console
$ helm upgrade --name px-central portworx/px-central --namespace central --set pxbackup.enabled=false
```

## Advanced Configuration

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
  namespace: central
```

2. Pass the secret name to chart using flag: `--set caCertsSecretName=<SECRET_NAME>`

### Expose PX-Central UI on openshift routes and access using http and https:
1. Create single route with hostname and path: `/` and point it to `px-central-ui` service. 
2. Access PX-Central UI using route endpoint.
Note: Keycloak auth and Grafana UI will be accessible on same endpoint on different paths: `/auth` and `/grafana`.

## FAQ

1. How to check install logs:
   To get the logs of post install hook:
   ```console
   $ kubectl logs -f --namespace {{ .Release.Namespace }} -ljob-name=pxcentral-post-install-hook
   ```

# PX-Monitor

Using PX-Monitor, you can manage and monitor portworx cluster metrics.
By default PX-Monitor remains disabled with px-central installation.

### Prerequisites:
- PX-Central chart has to be deployed and all components should be in running state.
- Edit `privileged` scc using command : `oc edit scc privileged` and add following into `users` section : `- system:serviceaccount:<PX_BACKUP_NAMESPACE>:px-monitor` change the PX_BACKUP_NAMESPACE.

Note:

- To fetch `PX_CENTRAL_UI_ENDPOINT`:
   - External IP of `px-central-ui` service 
   - `px-central-ui` ingress host or address

## Enabling PX-Monitor

To enable PX-Monitor :

1. helm get values --namespace central px-central -o yaml > values.yaml

2. Delete post install job: `kubectl delete job -n central pxcentral-post-install-hook`

3. Run following helm upgrade command to enable px-monitor for same px-central chart

Helm 3:
```console
$ helm upgrade px-central portworx/px-central --namespace central --create-namespace --set pxmonitor.enabled=true,installCRDs=true,pxmonitor.pxCentralEndpoint=<PX_BACKUP_UI_ENDPOINT>
```

Helm 2:
```console
$ helm install --name px-central portworx/px-central --namespace central --set pxmonitor.enabled=true,installCRDs=true,pxmonitor.pxCentralEndpoint=<PX_BACKUP_UI_ENDPOINT>
```

## Disabling PX-Monitor

To disable PX-Monitor:

1. helm get values --namespace central px-central -o yaml > values.yaml

2. Delete post install job: `kubectl delete job -n central pxcentral-post-install-hook`

3. Run following helm upgrade command to disable px-monitor for same px-central chart

Helm 3:
```console
$ helm upgrade px-central portworx/px-central --namespace central --create-namespace --set pxmonitor.enabled=false
```

Helm 2:
```console
$ helm upgrade --name px-central portworx/px-central --namespace central --set pxmonitor.enabled=false
```

## Advanced Configuration

### Expose PX-Central UI with metrics frontend(Grafana) on ingress:

- Edit the current px-central-ui ingress and add grafana and cortex endpoints, complete ingress spec are as follows:

- Example - 1:
```
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  annotations:
    kubernetes.io/ingress.class: nginx
  name: px-central-ui-ingress
  namespace: central
spec:
  rules:
  - http:
      paths:
      - backend:
          serviceName: px-central-ui
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
  name: px-central-ui-ingress
  namespace: central
spec:
  rules:
  - host: px-central-ui.test-1.us-east.containers.appdomain.cloud
    http:
      paths:
      - backend:
          serviceName: px-central-ui
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
    - px-central-ui.test-1.us-east.containers.appdomain.cloud
    secretName: test
```
Note: Change the secret and hosts based on your configuration. Also, `secretName` -> `kubernetes TLS certificates secret` is required only when you want to terminate TLS on the host/domain.
- Some examples:
  - AKS: https://docs.microsoft.com/en-us/azure/aks/ingress-own-tls
  - EKS: https://aws.amazon.com/blogs/opensource/network-load-balancer-nginx-ingress-controller-eks/


# PX-License-Server

Using PX-License-Server, you can manage license for all your portworx clusters.
By default PX-License-Server remains disabled with px-central installation.

### Prerequisites:
- Set `px/ls=true` label to any of two worker nodes.
```console
$ kubectl label node <NODE_NAME> px/ls=true
```
- For openshift cluster:
1. Edit `privileged` scc using command : `oc edit scc privileged` and add following into `users` section : `- system:serviceaccount:<PX_BACKUP_NAMESPACE>:pxcentral-license-server` change the PX_BACKUP_NAMESPACE.
2. Enable SSH access on port 7070, To configure same add following into worker nodes where `px/ls=true` label is set: 
   - `-A INPUT -p tcp -m state --state NEW -m tcp --dport 7070 -j ACCEPT` in `/etc/sysconfig/iptables` file
   - Restart iptables service: `systemctl restart iptables.service`

## Enabling PX-License-Server

  ### To enable PX-License-Server along with px-central install:

    Helm 3:
    ```console
    $ helm install px-central portworx/px-central --namespace central --create-namespace --set pxlicenseserver.enabled=true
    ```

    Helm 2:
    ```console
    $ helm install --name px-central portworx/px-central --namespace central --set pxlicenseserver.enabled=true
    ```
  
  ### To enable PX-License-Server on already deployed px-central

  1. helm get values --namespace central px-central -o yaml > values.yaml

  2. Delete post install job: `kubectl delete job -n central pxcentral-post-install-hook`

  3. Run following helm upgrade command to enable px-license-server for same px-central chart

  Helm 3:
  ```console
  $ helm upgrade px-central portworx/px-central --namespace central --create-namespace --set pxlicenseserver.enabled=true
  ```

  Helm 2:
  ```console
  $ helm upgrade --name px-central portworx/px-central --namespace central --set pxlicenseserver.enabled=true
  ```

## Disabling PX-License-Server

To disable PX-License-Server along with px-central:

Helm 3:
```console
$ helm upgrade px-central portworx/px-central --namespace central --create-namespace --set pxlicenseserver.enabled=false
```

Helm 2:
```console
$ helm upgrade --name px-central portworx/px-central --namespace central --set pxlicenseserver.enabled=false
```

## Parameters

The following tables lists the configurable parameters of the PX-Backup chart and their default values.

### PX-Central parameters

Parameter | Description | Default
--- | --- | ---
`persistentStorage` | Persistent storage for all px-central components | `""`
`persistentStorage.enabled` | Enable persistent storage | `true`
`persistentStorage.storageClassName` | Provide storage class name which exists | `""`
`persistentStorage.mysqlVolumeSize` | MySQL volume size | `"100Gi"`
`persistentStorage.keycloakThemeVolumeSize` | Keycloak frontend theme volume size | `"5Gi"`
`persistentStorage.keycloakBackendVolumeSize` | Keycloak backend volume size | `"10Gi"`
`storkRequired` | Scheduler name as stork | `false`
`nodeAffinityLabel` | Label for node affinity for px-central components | `""`
`podAntiAffinity` | PodAntiAffinity will make sure pods are distributed | `false`
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
`securityContext` | Security context for the pod | `{runAsUser: 1000, fsGroup: 1000, runAsNonRoot: true}`
`postInstallJob.sslEnabled` | k8s apis with ssl enabled in post-install-job pod | `true`
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
`images.postInstallSetupImage.registry` | PX-Backup post install setup image registry | `docker.io`
`images.postInstallSetupImage.repo` | PX-Backup post install setup image repo | `portworx`
`images.postInstallSetupImage.imageName` | PX-Backup post install setup image name | `pxcentral-onprem-post-setup`
`images.postInstallSetupImage.tag` | PX-Backup post install setup image tag | `1.2.2`
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

### PX-Backup parameters

Parameter | Description | Default
--- | --- | ---
`images` | PX-Backup deployment images | `""`
`pxbackup.enabled` | Enabled PX-Backup | `false`
`pxbackup.orgName` | PX-Backup organization name | `default`
`images.pxBackupImage.registry` | PX-Backup image registry | `docker.io`
`images.pxBackupImage.repo` | PX-Backup image repo | `portworx`
`images.pxBackupImage.imageName` | PX-Backup image name | `px-backup`
`images.pxBackupImage.tag` | PX-Backup image tag | `1.2.2`
`images.mongodbImage.registry` | PX-Backup mongodb image registry | `docker.io`
`images.mongodbImage.repo` | PX-Backup mongodb image repo | `bitnami`
`images.mongodbImage.imageName` | PX-Backup mongodb image name | `mongodb`
`images.mongodbImage.tag` | PX-Backup mongodb image tag | `4.4.4-debian-10-r30`

### PX-Monitor parameters

Parameter | Description | Default
--- | --- | ---
`pxmonitor` | PX Monitor deployment | ``
`pxmonitor.enabled` | PX-Central cluster enabled monitor component | `false`
`pxmonitor.pxCentralEndpoint` | PX-Central endpoint (LB endpoint of px-central-ui service, ingress host) | ``
`pxmonitor.sslEnabled` | PX-Central UI is accessibe on https | `false`
`pxmonitor.oidcClientID` | PX-Central internal oidc client ID | `pxcentral`
`pxmonitor.oidcClientSecret` | PX-Central internal oidc client secret | ``
`pxmonitor.consulBindInterface` | Exclusive bind interface for consul (ex: eth0) | `""`
`pxmonitor.cortex.alertmanager.advertiseAddress` | Advertise address for alert manager (supported values - "pod_ip") | `""`
`installCRDs` | Install metrics stack required crds | `false`
`storkRequired` | Scheduler name as stork | `false`
`clusterDomain` | Cluster domain | `cluster.local`
`cassandraUsername` | Cassandra cluster username | `cassandra`
`cassandraPassword` | Cassandra cluster password | `cassandra`
`persistentStorage` | Persistent storage for all px-central px-monitor components | `""`
`persistentStorage.enabled` | Enable persistent storage | `false`
`persistentStorage.storageClassName` | Provide storage class name which exists | `""`
`persistentStorage.cassandra.storage` | Cassandra volumes size | `8Gi`
`persistentStorage.grafana.storage` | Grafana volumes size | `20Gi`
`persistentStorage.consul.storage` | Consul volumes size | `8Gi`
`securityContext` | Security context for the pod | `{runAsUser: 1000, fsGroup: 1000, runAsNonRoot: true}`
`images` | PX monitor stack images | ``
`images.pullSecrets` | Image pull secret | `docregistry-secret`
`images.pullPolicy` | Image pull policy | `Always`

### PX-License-Server parameters

The following table lists the configurable parameters of the PX-License-Server chart and their default values.

Parameter | Description | Default
--- | --- | ---
`pxlicenseserver` | PX license server deployment | ``
`pxlicenseserver.enabled` | PX-Central cluster enabled license server component | `false`
`pxlicenseserver.internal` | PX-Central cluster license server | ``
`pxlicenseserver.internal.enabled` | PX-Central cluster license server enabled | `true`
`pxlicenseserver.internal.lsTypeUAT` | PX license server deployment type [UAT] | `false`
`pxlicenseserver.internal.lsTypeAirgapped` | PX license server deployment type [Air-gapped] | `false`
`pxlicenseserver.external.enabled` | External license server enabled | `false`
`pxlicenseserver.mainNodeIP` | External license server main node endpoints | ``
`pxlicenseserver.backupNodeIP` | External license server backup node endpoints | ``
`pxlicenseserver.adminUserName` | PX license server admin user name | `admin`
`pxlicenseserver.adminUserPassword` | PX license server admin user password | `Adm1n!Ur`
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
