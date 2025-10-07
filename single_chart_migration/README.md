# Upgrading to Single Chart from 1.2.x to 2.0.0

PX-Central with 1.2.x has 3 different charts.
   - px-backup
   - px-monitor
   - px-license-server

From 2.0.0, px-central is supported with a single chart (px-central) and the above features components can be enabled or disabled.


### Steps to Upgrade:

- Downloading migration.sh .

```console
$ curl https://raw.githubusercontent.com/portworx/helm/master/single_chart_migration/migration.sh -o migration.sh
```

- Make migration.sh executable

```console
$ chmod +x migration.sh
```

- Update helm repository:
```console
$ helm repo update
```

- Search for portworx repo:

```console
$ helm search repo portworx
```

- Get the namespace in which px-central components have been installed
```console
$ helm ls -A | grep "px-backup-[0-9].[0-9].[0-9]" | awk '{print $2}'
```

- Run migration.sh to upgrade to 2.0.0

```console
$ ./migration.sh --namespace <namespace> --helmrepo <helm repo name> --admin-password <current admin user password>
```

**px-backup-ui service has been kept for backward compatibility but will soon be deprecated. Please modify the ingress or routes which have been using px-backup-ui service to use px-central-ui service instead.**
