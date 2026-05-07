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
`images.pullSecrets` | Image pull secret | `docregistry-secret`
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
