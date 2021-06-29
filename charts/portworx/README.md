# Portworx

[Portworx](https://portworx.com/) is a software defined persistent storage solution designed and purpose built for applications deployed as containers, via container orchestrators such as Kubernetes, Marathon and Swarm. It is a clustered block storage solution and provides a Cloud-Native layer from which containerized stateful applications programmatically consume block, file and object storage services directly through the scheduler.

## Pre-requisites
The helm chart (portworx-helm) deploys Portworx and STork(https://docs.portworx.com/scheduler/kubernetes/stork.html) on your Kubernetes cluster. The minimum requirements for deploying the helm chart are as follows:

- Helm has been installed on the client machine from where you would install the chart. (https://docs.helm.sh/using_helm/#installing-helm)
- Tiller version 2.9.0 and above is running on the Kubernetes cluster where you wish to deploy Portworx.
- Tiller has been provided with the right RBAC permissions for the chart to be deployed correctly.
- Kubernetes 1.7+
- All [Pre-requisites](https://docs.portworx.com/#minimum-requirements). for Portworx fulfilled.

## Installing the Chart

To install the chart with the release name `my-release` run the following commands substituting relevant values for your setup:

##### NOTE:
`etcdEndPoint` is a required field. The chart installation would not proceed unless this option is provided.
If the etcdcluster being used is a secured ETCD (SSL/TLS) then please follow instructions to create a kubernetes secret with the certs. https://docs.portworx.com/scheduler/kubernetes/etcd-certs-using-secrets.html#create-kubernetes-secret


`clusterName` should be a unique name identifying your Portworx cluster. The default value is `mycluster`, but it is suggested to update it with your naming scheme.

For eg:
```
git clone https://github.com/portworx/helm.git
helm install --debug --name my-release --set etcdEndPoint=etcd:http://192.168.70.90:2379,clusterName=$(uuidgen) ./helm/charts/portworx/
```

## Configuration

The following tables lists the configurable parameters of the Portworx chart and their default values.

| Parameter | Description |
|--------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `deploymentType` | The deployment type. Can be either docker/oci |
| `imageVersion` | The image tag to pull |
| `openshiftInstall` | Installing on Openshift? |
| `pksInstall` | Installing on Pivotal Container service? |
| `EKSInstall` | Installing EKS (Amazon Elastic Container service) |
| `AKSInstall` | Installing on AKS (Azure Kubernetes service) |
| `etcdEndPoint` | (REQUIRED) ETCD endpoint for PX to function properly in the form "etcd:http://<your-etcd-endpoint>". Multiple Urls should be semi-colon seperated example: etcd:http://<your-etcd-endpoint1>;etcd:http://<your-etcd-endpoint2> |
| `clusterName` | Portworx Cluster Name |
| `usefileSystemDrive` | Should Portworx use an unmounted drive even with a filesystem ? |
| `usedrivesAndPartitions` | Should Portworx use the drives as well as partitions on the disk ? |
| `secretType` | Secrets store to be used can be AWS KMS/KVDB/Vault/K8s/IBM Key Protect |
| `drives` | Semi-colon seperated list of drives to be used for storage (example: "/dev/sda;/dev/sdb") |
| `dataInterface` | Name of the interface <ethX> |
| `managementInterface` | Name of the interface <ethX> |
| `envVars` | semi-colon-separated list of environment variables that will be exported to portworx. (example: MYENV1=val1;MYENV2=val2) |
| `stork` | [Storage Orchestration for Hyperconvergence](https://github.com/libopenstorage/stork). |
| `storkVersion` | The version of stork |
| `customRegistryURL` | Custom Docker registry |
| `registrySecret` | Registry secret |
| `journalDevice` | Journal device for Portworx metadata |
| `aut` | Enable AutoPilot (Tech Preview) |
| `csi` | Enable CSI (Tech Preview) |
| `internalKVDB` | Internal KVDB store |
| `etcd.credentials` | Username and password for ETCD authentication in the form user:password |
| `etcd.certPath` | Base path where the certificates are placed. (example: if the certificates ca,.crt and the .key are in /etc/pwx/etcdcerts the value should be provided as /etc/pwx/etcdcerts Refer: https://docs.portworx.com/scheduler/kubernetes/etcd-certs-using-secrets.html) |
| `etcd.ca` | Location of CA file for ETCD authentication. Should be /path/to/server.ca |
| `etcd.cert` | Location of certificate for ETCD authentication. Should be /path/to/server.crt |
| `etcd.key` | Location of certificate key for ETCD authentication Should be /path/to/servery.key |
| `consul.acl` | ACL token value used for Consul authentication. (example: 398073a8-5091-4d9c-871a-bbbeb030d1f6) |

Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`. For example,

## Cloud installs

#### Installing on AKS 

Details are [here](https://docs.portworx.com/portworx-install-with-kubernetes/cloud/azure/aks/2-deploy-px/).

> **Tip**: In this case the chart is located at `./helm/charts/portworx`, do change it as per your setup.
```
helm install --name my-release --set imageVersion=1.2.12.0,etcdEndPoint=etcd:http://192.168.70.90:2379 ./helm/charts/portworx/
```

Alternatively, a YAML file that specifies the values for the parameters can be provided while installing the chart. For example,
```
helm install --name my-release -f ./helm/charts/portworx/values.yaml ./helm/charts/portworx
```
> **Tip**: You can use the default [values.yaml](values.yaml) and make changes as per your requirement

#### Installing on IKS [ IBM Cloud ] 

Refer the IBM charts [here](https://github.com/IBM/charts/tree/master/community/portworx)

> **Tip**: You will need to add the IBM charts repo with the repo path set to rawgithub
```
helm repo add ibm-porx https://raw.githubusercontent.com/IBM/charts/master/repo/community
```

## Upgrading Portworx Install

You can update the `imageVersion` value in the YAML file that specifies the values for the parameters used while installing the chart.
```
helm upgrade my-release -f ./helm/charts/portworx/values.yaml ./helm/charts/portworx
```

Alternatively, you can also use the `--set` directive to do the same. For example,
```
helm upgrade my-release --set imageVersion=<px-version>,etcdEndPoint=<list-of-etcd-endpoints>,clusterName=<cluster-name> -f ./helm/charts/portworx/values.yaml  ./helm/charts/portworx 
```

> **Tip**: You can check the upgrade with the new values took effect using. Check the reference for upgrade [here](https://v2.helm.sh/docs/using_helm/#helm-upgrade-and-helm-rollback-upgrading-a-release-and-recovering-on-failure)
```
helm get values my-release
```

## Uninstalling the Chart

To uninstall/delete the `my-release` deployment:
The chart would follow the process as outlined here. (https://docs.portworx.com/scheduler/kubernetes/install.html#uninstall)

> **Tip** > The Portworx configuration files under `/etc/pwx/` directory are preserved, and will not be deleted.

```
helm delete my-release
```
The command removes all the Kubernetes components associated with the chart and deletes the release.

### Basic troubleshooting

#### Helm install errors with `no available release name found`

```
helm install --dry-run --debug --set etcdEndPoint=etcd:http://192.168.70.90:2379,clusterName=$(uuidgen) ./helm/charts/portworx/
[debug] Created tunnel using local port: '37304'
[debug] SERVER: "127.0.0.1:37304"
[debug] Original chart version: ""
[debug] CHART PATH: /root/helm/charts/portworx

Error: no available release name found
```
This most likely indicates that Tiller doesn't have the right RBAC permissions.
You can verify the tiller logs
```
[storage/driver] 2018/02/07 06:00:13 get: failed to get "singing-bison.v1": configmaps "singing-bison.v1" is forbidden: User "system:serviceaccount:kube-system:default" cannot get configmaps in the namespace "kube-system"
[tiller] 2018/02/07 06:00:13 info: generated name singing-bison is taken. Searching again.
[tiller] 2018/02/07 06:00:13 warning: No available release names found after 5 tries
[tiller] 2018/02/07 06:00:13 failed install prepare step: no available release name found
```



