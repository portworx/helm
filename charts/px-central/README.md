# PX-Central

PX-Central is a unified, multi-user, multi-cluster management interface. Using PX-Central, users can backup/restore Kubernetes clusters with PX-Backup. Optionally, users can also use PX-Central to manage and monitor their PX clusters from a single place. PX-Central can also host a license server to manage Portworx licenses across your environment.

## Installing the Chart

To install the chart with the release name `px-backup`:

Add portworx/px-central helm repository using command:
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
portworx/px-central     1.0.0                           A Helm chart for installing PX-Backup with PX-C...
```

Helm 3:
```console
$ helm install px-backup portworx/px-central --namespace px-backup --create-namespace
```

Helm 2:
```console
$ helm install --name px-backup portworx/px-central --namespace px-backup
```

## Uninstalling the Chart

To uninstall/delete the `px-backup` chart:

```console
$ helm delete px-backup --namespace px-backup
```
OR
```console
$ kubectl delete ns px-backup
```

## Configuration

The following table lists the configurable parameters of the Keycloak chart and their default values.

Parameter | Description | Default
--- | --- | ---
`namespace` | Namespace to install px-central and px-backup | `px-backup`
`customeRegistryEnabled` | Custom registry based install | `false`
`dockerRegistryURL` | Docker registry URl | `docker.io`
`dockerImageRepoName` | Docker images repository name | `portworx`
`imagePullSecrets` | Image pull secret for custom registry | `docregistry-secret`
`imagePullPolicy` | Image pull policy | `Always`
`persistentStorage` | Persistent storage for all px-central components | `[]`
`persistentStorage.enabled` | Enable persistent storage | `true`
`persistentStorage.storageClassName` | Provide storage class name which exists | `[]`
`nodeAffinityKey` | Node affinity key to deploy all central components on specific nodes | `pxc/enabled`
`nodeAffinityValue` | Node affinity value to deploy all central components on specific nodes | `false`
`storkRequired` | Scheduler name as stork | `false`
`isOpenshiftCluster` | Deployment on openshift cluster | `false`
`ingressControllerSetup` | Ingress controller deployment required | `true`
`centralEndpoint` | PX-Central ingress endpoint (Hostname or public IP) | default `None`
`centralOIDC` | PX-Central OIDC | `[]`
`centralOIDC.enabled` | PX-Central OIDC | `true`
`centralOIDC.username` | PX-Central OIDC username | `admin`
`centralOIDC.password` | PX-Central OIDC admin user password | `admin`
`centralOIDC.email` | PX-Central OIDC admin user email | `admin@portworx.com`
`centralOIDC.keyCloakBackendPassword` | Keycloak backend store password | `keycloak`
`centralOIDC.clientId` | PX-Central OIDC client id | `pxcentral`
`centralOIDC.clientSecret` | PX-Central OIDC client secret | `dummy`
`externalOIDC` | Enable external OIDC provider | `[]`
`externalOIDC.enabled` | Enabled external OIDC provider | `false`
`externalOIDC.clientID` | External OIDC client ID | default `test`
`externalOIDC.clientSecret` | External OIDC client secret | `test`
`externalOIDC.endpoint` | External OIDC endpoint | `test`
`pxbackup` | Enable PX-Backup | `[]`
`pxbackup.enabled` | Enabled PX-Backup | `true`
`pxbackup.orgName` | PX-Backup organization name | `portworx`
