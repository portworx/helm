## Before creating any new objects following needs to updated based on current px-central onprem deployment:

- In create_new_pvc_from_snapshot.yaml
- Change the labels:
```
app.kubernetes.io/name: px-backup
app.kubernetes.io/version: 1.0.0
```
- Change the Annotations:
```
meta.helm.sh/release-name: px-backup
meta.helm.sh/release-namespace: portworx 
stork.libopenstorage.org/snapshot-source-namespace: portworx
```

- In create_volume_snapshot_from_pvc.yaml change namespace `namespace: portworx` to current onprem central deployed namespace.

## Steps to upgrade operator based onprem central deployment to helm chart.

1. Create volumesnapshot from existing onprem central pvc's in the same namespace.
```console
$ kubectl apply -f create_volume_snapshot_from_pvc.yaml
```

2. Verfiy volume snapshot for all pvc's are available in the same namespace.
```console
$ storkctl get snapshot --namespace portworx
```

3. Cleanup existing px-central-onprem deployment using cleanup script.
- If current px-central-onprem is using existing portworx cluster for persistence storage then use following commands for cleanup:
```console
$ curl -o px-central-cleanup.sh 'https://raw.githubusercontent.com/portworx/px-central-onprem/1.0.4/cleanup.sh'
$ bash px-central-cleanup.sh
```
- If portworx cluster deployment is part of px-central-onprem cluster, then use following commands for cleanup:
```console
$ curl -o px-central-cleanup.sh 'https://raw.githubusercontent.com/portworx/px-central-onprem/1.0.4/pxcentral-components-cleanup.sh'
$ bash px-central-cleanup.sh
```

4. Create new pvc's from volume snapshots(step 1) into same namespace where px-central-onprem was deployed.
```console
$ kubectl apply -f create_new_pvc_from_snapshot.yaml
```

5. Install PX-Backup using helm chart.
```console
$ helm repo add portworx http://charts.portworx.io/
$ helm repo update
$ helm install px-backup portworx/px-backup --namespace portworx --create-namespace --set persistentStorage.enabled=true,persistentStorage.storageClassName=stork-snapshot-sc,operatorToChartUpgrade=true,pxbackup.orgName=test,pxcentralDBPassword=singapore
```
`Note: In the above helm install command, mention the same organization name which was used in previous operator based install.`