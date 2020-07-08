# PX-Backup

PX-Central is a unified, multi-user, multi-cluster management interface. Using PX-Backup, users can backup/restore Kubernetes clusters with PX-Backup.

## Installing the Chart

To install the chart with the release name `px-backup`:

Add portworx/px-backup helm repository using command:
```console
$ helm repo add portworx https://raw.githubusercontent.com/portworx/helm/master/stable
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
NAME                    CHART VERSION   APP VERSION     DESCRIPTION                                       
portworx/portworx       1.0.0                           A Helm chart for installing Portworx on Kuberne...
portworx/px-backup      1.0.0                           A Helm chart for installing PX-Backup with PX-C...
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
`namespace` | Namespace to install px-central and px-backup | `px-backup`
`persistentStorage` | Persistent storage for all px-central components | `[]`
`persistentStorage.enabled` | Enable persistent storage | `false`
`persistentStorage.storageClassName` | Provide storage class name which exists | `[]`
`storkRequired` | Scheduler name as stork | `false`
`ingressControllerSetup` | Ingress controller deployment required | `false`
`centralEndpoint` | PX-Central ingress endpoint (Hostname or public IP) | default `None`
`oidc` | Enable OIDC for PX-Central and PX-backup for RBAC | `[]`
`oidc.centralOIDC` | PX-Central OIDC | `[]`
`oidc.centralOIDC.enabled` | PX-Central OIDC | `true`
`oidc.centralOIDC.defaultUsername` | PX-Central OIDC username | `admin`
`oidc.centralOIDC.defaultPassword` | PX-Central OIDC admin user password | `admin`
`oidc.centralOIDC.defaultEmail` | PX-Central OIDC admin user email | `admin@portworx.com`
`oidc.centralOIDC.keyCloakBackendPassword` | Keycloak backend store password | `keycloak`
`oidc.centralOIDC.clientId` | PX-Central OIDC client id | `pxcentral`
`oidc.centralOIDC.clientSecret` | PX-Central OIDC client secret | `dummy`
`oidc.externalOIDC` | Enable external OIDC provider | `[]`
`oidc.externalOIDC.enabled` | Enabled external OIDC provider | `false`
`oidc.externalOIDC.clientID` | External OIDC client ID | default `test`
`oidc.externalOIDC.clientSecret` | External OIDC client secret | `test`
`oidc.externalOIDC.endpoint` | External OIDC endpoint | `test`
`images` | PX-Backup deployment images | `[]`
`images.customRegistryEnabled` | Custom registry based install | `false`
`images.registry` | Docker registry URl | `docker.io`
`images.repo` | Docker images repository name | `portworx`
`images.pullSecrets` | Image pull secret for custom registry | `docregistry-secret`
`images.pullPolicy` | Image pull policy | `Always`
`pxbackup` | Enable PX-Backup | `[]`
`pxbackup.enabled` | Enabled PX-Backup | `true`
`pxbackup.orgName` | PX-Backup organization name | `portworx`
