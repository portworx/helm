# Upgrading to Single Chart in 1.3.0

PX-Central with 1.2.x has 3 different charts.
   - px-backup
   - px-monitor
   - px-license-server

From 1.3.0, px-central is supported with a single chart (px-central) and the above features components can be enabled or disabled.

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

- Run migration.sh to upgrade to 1.3.0

```console
$ ./migration.sh --namespace <namespace> --helmrepo <helm repo name>
```