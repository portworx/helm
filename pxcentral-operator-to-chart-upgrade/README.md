## Steps to upgrade operator based onprem central deployment to helm chart.

1. Create volumesnapshot from existing onprem central pvc's in the same namespace.
```console
$ kubectl apply -f create_volume_snapshot_from_pvc.yaml
```

2. Verfiy volume snapshot for all pvc's are available in the same namespace.
```console
$ kubectl get volumesnapshot --namespace portworx
$ kubectl get volumesnapshotdata --namespace portworx
```

3. Cleanup existing px-central-onprem deployment using cleanup script.
```console
$ curl -o px-central-cleanup.sh 'https://raw.githubusercontent.com/portworx/px-central-onprem/1.0.3/cleanup.sh'
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
$ helm install px-backup portworx/px-backup --namespace portworx --create-namespace --set persistentStorage.enabled=true,persistentStorage.storageClassName=stork-snapshot-sc,operatorToChartUpgrade=true,pxbackup.orgName=test
```
`Note: In the above helm install command, mention the same organization name which was used in previous operator based install.`