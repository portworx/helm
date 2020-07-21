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
portworx/px-backup      1.0.0           1.0.2-rc1           A Helm chart for installing PX-Backup with PX-C...
```

Helm 3:
```console
$ helm install px-backup portworx/px-backup --namespace px-backup --create-namespace
```

Helm 2:
```console
$ helm install --name px-backup portworx/px-backup --namespace px-backup
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
`storkRequired` | Scheduler name as stork | `false`
`pxcentralDBPassword` | PX-Central cluster store mysql database password | `Password1`
`oidc` | Enable OIDC for PX-Central and PX-backup for RBAC | `""`
`oidc.centralOIDC` | PX-Central OIDC | `""`
`oidc.centralOIDC.enabled` | PX-Central OIDC | `true`
`oidc.centralOIDC.defaultUsername` | PX-Central OIDC username | `admin`
`oidc.centralOIDC.defaultPassword` | PX-Central OIDC admin user password | `admin`
`oidc.centralOIDC.defaultEmail` | PX-Central OIDC admin user email | `admin@portworx.com`
`oidc.centralOIDC.keyCloakBackendUserName` | Keycloak backend store username | `keycloak`
`oidc.centralOIDC.keyCloakBackendPassword` | Keycloak backend store password | `keycloak`
`oidc.centralOIDC.clientId` | PX-Central OIDC client id | `pxcentral`
`oidc.centralOIDC.clientSecret` | PX-Central OIDC client secret | `dummy`
`oidc.externalOIDC` | Enable external OIDC provider | `""`
`oidc.externalOIDC.enabled` | Enabled external OIDC provider | `false`
`oidc.externalOIDC.clientID` | External OIDC client ID | default `""`
`oidc.externalOIDC.clientSecret` | External OIDC client secret | `""`
`oidc.externalOIDC.endpoint` | External OIDC endpoint | `""`
`images` | PX-Backup deployment images | `""`
`pxbackup` | Enable PX-Backup | `""`
`pxbackup.enabled` | Enabled PX-Backup | `true`
`pxbackup.orgName` | PX-Backup organization name | `default`
`pxbackup.externalAccessHttpPort` | PX-Backup ui http port | `31234`
`securityContext` | Security context for the pod | `{runAsUser: 1000, fsGroup: 1000, runAsNonRoot: true}`
`images.pullSecrets` | Image pull secrets | `docregistry-secret`
`images.pullPolicy` | Image pull policy | `Always`
`images.pxcentralApiServerImage.registry` | API server image registry | `docker.io`
`images.pxcentralApiServerImage.repo` | API server image repo | `portworx`
`images.pxcentralApiServerImage.imageName` | API server image name | `pxcentral-onprem-api`
`images.pxcentralApiServerImage.tag` | API server image tag | `1.0.4`
`images.pxcentralFrontendImage.registry` | PX-Central frontend image registry | `docker.io`
`images.pxcentralFrontendImage.repo` | PX-Central frontend image repo | `portworx`
`images.pxcentralFrontendImage.imageName` | PX-Central frontend image name | `pxcentral-onprem-ui-frontend`
`images.pxcentralFrontendImage.tag` | PX-Central frontend image tag | `1.1.1`
`images.pxcentralBackendImage.registry` | PX-Central backend image registry | `docker.io`
`images.pxcentralBackendImage.repo` | PX-Central backend image repo | `portworx`
`images.pxcentralBackendImage.imageName` | PX-Central backend image name | `pxcentral-onprem-ui-backend`
`images.pxcentralBackendImage.tag` | PX-Central backend image tag | `1.1.1`
`images.pxcentralMiddlewareImage.registry` | PX-Central middleware image registry | `docker.io`
`images.pxcentralMiddlewareImage.repo` | PX-Central middleware image repo | `portworx`
`images.pxcentralMiddlewareImage.imageName` | PX-Central middleware image name | `pxcentral-onprem-ui-lhbackend`
`images.pxcentralMiddlewareImage.tag`| PX-Central middleware image tag | `1.1.1`
`images.pxBackupImage.registry` | PX-Backup image registry | `docker.io`
`images.pxBackupImage.repo` | PX-Backup image repo | `portworx`
`images.pxBackupImage.imageName` | PX-Backup image name | `px-backup`
`images.pxBackupImage.tag` | PX-Backup image tag | `1.0.2-rc1`
`images.postInstallSetupImage.registry` | PX-Backup post install setup image registry | `docker.io`
`images.postInstallSetupImage.repo` | PX-Backup post install setup image repo | `portworx`
`images.postInstallSetupImage.imageName` | PX-Backup post install setup image name | `pxcentral-onprem-post-setup`
`images.postInstallSetupImage.tag` | PX-Backup post install setup image tag | `1.0.4`
`images.etcdImage.registry` | PX-Backup etcd image registry | `docker.io`
`images.etcdImage.repo` | PX-Backup etcd image repo | `bitnami`
`images.etcdImage.imageName` | PX-Backup etcd image name | `etcd`
`images.etcdImage.tag` | PX-Backup etcd image tag | `3.4.7-debian-10-r14`
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
`images.keycloakLoginThemeImage.tag` | PX-Backup keycloak login theme image tag | `1.0.1`
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
      - backend:
          serviceName: pxcentral-lh-middleware
          servicePort: 8091
        path: /lhBackend
      - backend:
          serviceName: pxcentral-backend
          servicePort: 80
        path:  /backend
  tls:
  - hosts:
    - px-backup-ui.test-1.us-east.containers.appdomain.cloud
    secretName: test
' > /tmp/px-backup-ui-ingress.yaml
```

2. Change the secret and hosts based on your configuration and apply the spec:
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

2. Get the node port (NODE_PORT) of service: `px-backup-ui`. Default node port is set to 31234, but it is configurable and can be set using: `pxbackup.externalAccessHttpPort`

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


## FAQ

1. How to check install logs:
   To get the logs of post install hook:
   ```console
   $ kubectl logs -f --namespace {{ .Release.Namespace }} -ljob-name=pxcentral-post-install-hook
   ```