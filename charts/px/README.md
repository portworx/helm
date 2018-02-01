# Portworx

[Portworx](https://portworx.com/) is a software defined persistent storage solution designed and purpose built for applications deployed as containers, via container orchestrators such as Kubernetes, Marathon and Swarm. It is a clustered block storage solution and provides a Cloud-Native layer from which containerized stateful applications programmatically consume block, file and object storage services directly through the scheduler.

## Introduction

This chart deploys Portworx to all nodes in your cluster via a DaemonSet.

## Prerequisites

- Kubernetes 1.7+
- All [Pre-requisites](https://docs.portworx.com/#minimum-requirements). for Portworx fulfilled. 

## Installing the Chart

To install the chart with the release name `my-release` run:

Clone the repository. 
cd into the root directory

```
$ helm install --name my-release \
    --set imageVersion=1.2.12.0 .
```

## Uninstalling the Chart

To uninstall/delete the `my-release` deployment:

```bash
$ helm delete my-release
```

The command removes all the Kubernetes components associated with the chart and deletes the release.

## Configuration

The following tables lists the configurable parameters of the Datadog chart and their default values.

|             Parameter       |            Description             |                    Default                |
|-----------------------------|------------------------------------|-------------------------------------------|
| `serviceAccount`            | Portworx service account name      |  `px-account`                             |
| `deploymentType`            | The deployment type. Can be either docker/OCI   | `oci`                 |
| `imageVersion`              | The image tag to pull              | `latest`                                  |
| `openshiftInstall`               | Installing on Openshift? | `false`                               |
| `isTargetOSCoreOS`        | Is target CoreOS       | `false`                                     |
| `installOptions.etcdEndpoint`          | (REQUIRED) ETCD endpoint for PX to function properly in the form "etcd:http://<your-etcd-endpoint>:2379" | `etcd:http://<your-etcd-endpoint>:2379`                    |
| `installOptions.clusterName`           | Portworx Cluster Name  | `mycluster`                                     |
| `installOptions.runOnMaster`             | Run Portworx on Kubernetes Master? | `false`                              |
| `installOptions.zeroStorage`           | Run Portworx on Master with Zero Storage? | `false`                     |
| `installOptions.usefileSystemDrive`      | Should Portworx use an unmounted drive even with a filesystem ? | `false`                |
| `installOptions.kubernetesVersion`    | The version of Kubernetes              | `1.7.8`                                    |
| `installOptions.secretType`      | Secrets store to be used can be AWS/KVDB/Vault          | `none`                                    |
| `installOptions.drives` | Comma seperated list of drives to be used for storage           | `none`                                   |
| `installOptions.dataInterface`   | Name of the interface <ethX>             | `none`                                   |
| `installOptions.lighthouse.token`  | Portworx lighthouse token for cluster. (example: token-a980f3a8-5091-4d9c-871a-cbbeb030d1e6) | `none`                                    |
| `installOptions.lighthouse.envVars`  | Comma-separated list of environment variables that will be exported to portworx. (example: API_SERVER=http://lighthouse-new.portworx.com) | `none`                                    |
| `installOptions.etcd.credentials`  | Username and password for ETCD authentication in the form user:password | `none:none`                                    |
| `installOptions.etcd.ca`  | Location of CA file for ETCD authentication. Should be /path/to/server.ca | `none`                                    |
| `installOptions.etcd.cert`  | Location of certificate for ETCD authentication. Should be /path/to/server.crt | `none`                                    |
| `installOptions.etcd.key`  | Location of certificate key for ETCD authentication Should be /path/to/servery.key | `none`                                    |
| `installOptions.etcd.acl`  | ACL token value used for Consul authentication. (example: 398073a8-5091-4d9c-871a-bbbeb030d1f6) | `none`                                    |


Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`. For example,

```bash
$ helm install --name my-release \
    --set deploymentType=docker,imageVersion=1.2.12.0 \
    .
```

Alternatively, a YAML file that specifies the values for the parameters can be provided while installing the chart. For example,

```bash
$ helm install --name my-release -f values.yaml .
```

> **Tip**: You can use the default [values.yaml](values.yaml)
