#!/bin/bash

# Script usage examples
# 
# Ex: ./migration.sh --namespace px-backup --helmrepo portworx --admin-password password
# When using the portworx/helm git repo directly for airgapped environments 
# Ex: ./migration.sh --namespace px-backup --helmrepo /root/portworx/helm --admin-password password

saListMonitor="px-monitor pxcentral-prometheus pxcentral-prometheus-operator"
secretListMonitor="pxcentral-cortex pxcentral-cortex-cassandra"
cmListMonitor="pxcentral-cortex-nginx pxcentral-grafana-dashboard-config pxcentral-grafana-dashboards pxcentral-grafana-ini-config pxcentral-grafana-source-config pxcentral-monitor-configmap"
pvcListMonitor="pxcentral-grafana-dashboards pxcentral-grafana-datasource pxcentral-mysql-pvc"
clusterroleListMonitor="pxcentral-prometheus pxcentral-prometheus-operator"
clusterrolebindingListMonitor="pxcentral-prometheus pxcentral-prometheus-operator"
roleListMonitor="px-monitor pxcentral-cortex"
rolebindingListMonitor="px-monitor pxcentral-cortex"
svcListMonitor="pxcentral-cortex-cassandra-headless pxcentral-cortex-cassandra pxcentral-memcached-index-read pxcentral-memcached-index-write pxcentral-memcached pxcentral-cortex-alertmanager-headless pxcentral-cortex-alertmanager pxcentral-cortex-configs pxcentral-cortex-distributor pxcentral-cortex-ingester pxcentral-cortex-querier pxcentral-cortex-query-frontend-headless pxcentral-cortex-consul pxcentral-cortex-query-frontend pxcentral-cortex-ruler pxcentral-cortex-table-manager pxcentral-prometheus"
stsListMonitor="pxcentral-cortex-cassandra pxcentral-memcached-index-read pxcentral-memcached-index-write pxcentral-memcached pxcentral-cortex-consul pxcentral-cortex-alertmanager pxcentral-cortex-ingester"
deploymentListMonitor="pxcentral-cortex-configs pxcentral-cortex-distributor pxcentral-cortex-nginx pxcentral-cortex-querier pxcentral-cortex-query-frontend pxcentral-cortex-ruler pxcentral-cortex-table-manager pxcentral-grafana pxcentral-prometheus-operator"
prometheusMonitor="pxcentral-prometheus"
prometheusruleMonitor="prometheus-portworx-rules-portworx.rules.yaml"
servicemonitorListMonitor="pxcentral-portworx px-backup"
statefulsetListMonitorDelete="pxcentral-memcached-index-read pxcentral-memcached-index-write pxcentral-memcached pxcentral-cortex-consul"
deploymentListMonitorDelete="pxcentral-prometheus-operator"

secretListLS="px-license-secret"
cmListLS="pxcentral-ls-configmap"
roleListLS="pxcentral-license-server"
svcListLS="pxcentral-license"
deploymentListLS="pxcentral-license-server"
deploymentListLSDelete="pxcentral-license-server"

namespace=""
pxbackup_release=""
pxmonitor_release=""
pxls_release=""
helm_cmd="helm"
kubectl_cmd="kubectl"

px_central_version="2.0.2"
pxbackup_enabled=false
pxmonitor_enabled=false
pxls_enabled=false

frontend_deployment="pxcentral-frontend"
cortex_nginx_deployment="pxcentral-cortex-nginx"
ls_configmap="pxcentral-ls-configmap"
post_install_job="pxcentral-post-install-hook"
cassandra_pvc_name="pxcentral-cassandra-data-pxcentral-cortex-cassandra-0"

job_registry="docker.io"
job_repo="portworx"
job_image="pxcentral-onprem-post-setup"
job_imagetag="2.0.2"
job_pull_secret="docregistry-secret"

mongo_registry="docker.io"
mongo_repo="bitnami"
mongo_image="mongodb"
mongo_imagetag="4.4.4-debian-10-r30"
mongo_pull_secret="docregistry-secret"

usage()
{
   echo ""
   echo "Usage: $0 --namespace <namespace> --helmrepo <helm repo name> --admin-password <current password of admin> --kubeconfig <kubeconfig file name>"
   echo -e "\t--namespace <namespace> namespace in which px-central charts are installed"
   echo -e "\t--helmrepo <helm repo name for px-central components> helm repo name , can get with helm repo list command"
   echo -e "\t--admin-password <current admin user password needed to update keycloak for RBAC settings> admin user current password"
   echo -e "\n\t Optional parameters"
   echo -e "\t--upgrade-version <version to upgrade to> px-central chart version to which upgrade will happen"
   echo -e "\t--kubeconfig <kubeconfig file path> kubeconfig file to set the context"
   echo -e "\t--air-gapped, this needs to be specified when the cluster is in airgapped environment."
   echo -e "\t--helm-values-file, file path of values.yaml which needs to be provided for airgapped clusters or if the last installation/upgrade has been done using the values.yaml"
   echo -e "\t--mongo-trial-migration if specified will do a trial migration from etcd to mongodb datastore"
   echo -e "\t--rollback-version, rollback will take the deployment to given version. This option should be used to get unblocked after mongodb migration failures."
   echo -e "\t--image-registry, image registry is required if images need to be pulled from custom registry when either mongo-trial-migration is set or rollback is required."
   echo -e "\t--image-repo, image repo is required if images need to be pulled from custom registry when either mongo-trial-migration is set or rollback is required."
   echo -e "\t--image-pull-secret image-pull-secret is required for for pulling the images from custom registry."

   echo -e "\t\t\t\t"
}

verify_release()
{
    namespace=$1
    release=$2
    echo "verifying if release $release exists in namespace $namespace"

    matches=`$helm_cmd list --namespace $namespace | awk -v rel="$release" '{if ($1 == rel) {print $1}}' | wc -l`
    if [ $matches -ne 1 ] ; then
        echo "release $release not found in namespace: $namespace"
        exit 1
    fi
}

change_annotation() {
    resourcetype=$1
    resource=$2

    does_exist_cmd="$kubectl_cmd -n $namespace get $resourcetype $resource"
    echo -e $does_exist_cmd
    $does_exist_cmd
    if [ $? -eq 0 ]; then
        cmd="$kubectl_cmd -n $namespace annotate $resourcetype $resource "meta.helm.sh/release-name=$pxbackup_release" --overwrite"
        echo -e $cmd
        $cmd
        if [ $? -ne 0 ]; then
            echo -e "Failed: $cmd, exiting from the update script"
            exit 1
        fi
        echo -e "Success: $cmd"
    fi
}

delete_resource() {
    resourcetype=$1
    resource=$2

    does_exist_cmd="$kubectl_cmd -n $namespace get $resourcetype $resource"
    echo -e $does_exist_cmd
    $does_exist_cmd
    if [ $? -eq 0 ]; then
        cmd="$kubectl_cmd -n $namespace delete $resourcetype $resource"
        echo -e $cmd
        $cmd
        if [ $? -ne 0 ]; then
            echo -e "Failed: $cmd, exiting from the update script"
            exit 1
        fi
        echo -e "Success: $cmd"
    fi
}

set_enabled_modules() {
    namespace=$1
    backup_match=`$kubectl_cmd --namespace $namespace get deployment px-backup`
    if [ $? -eq 0 ] ; then
        pxbackup_enabled=true
    fi

    monitor_match=`$kubectl_cmd --namespace $namespace get deployment pxcentral-cortex-distributor`
    if [ $? -eq 0 ] ; then
        pxmonitor_enabled=true
    fi

    ls_match=`$kubectl_cmd --namespace $namespace get configmap $cmListLS`
    if [ $? -eq 0 ] ; then
        pxls_enabled=true
    fi

}

find_releases() {
    namespace=$1
    # Finding px-backup release name from frontend deployment as px-backup may not be installed
    # px-backup release must be installed for 1.2.x chart versions
    pxbackup_release=`$kubectl_cmd --namespace $namespace get deployment $frontend_deployment  -o yaml | grep "^[ ]*meta.helm.sh/release-name:" | tail -1 | awk -F ":" '{print $2}' | awk '{$1=$1}1'`
    if [ "$pxbackup_release" == "" ]; then
        echo "px-backup is enabled but could not find the px-backup release"
        exit 1
    fi
    if [ "$pxmonitor_enabled" == true ]; then
        pxmonitor_release=`$kubectl_cmd --namespace $namespace get deployment $cortex_nginx_deployment  -o yaml | grep "^[ ]*meta.helm.sh/release-name:" | tail -1 | awk -F ":" '{print $2}' | awk '{$1=$1}1'`
        if [ "$pxmonitor_release" == "" ]; then
            echo "px-monitor is enabled but could not find the px-monitor release"
            exit 1
        fi
    fi

    # Checking configmap instead of deployment for licenseserver as part of upgrade we have to delete ls deployment 
    # And in case the script has to run again, then it will not get license-server release name.
    if [ "$pxls_enabled" == true ]; then
        pxls_release=`$kubectl_cmd --namespace $namespace get configmap $ls_configmap  -o yaml | grep "^[ ]*meta.helm.sh/release-name:" | tail -1 | awk -F ":" '{print $2}' | awk '{$1=$1}1'`
        if [ "$pxls_release" == "" ]; then
            echo "px-license-server is enabled but could not find the px-license-server release"
            exit 1
        fi
    fi
}

mongo_trial_migration() {

    namespace=$1
    mongodeployed=false
    image="$mongo_registry/$mongo_repo/$mongo_image:$mongo_imagetag"

    echo "mongotrialmigration case"
    # Get the storage class from the etcd PVC and use it for mongo PVC.
    sc=`$kubectl_cmd get pvc pxc-etcd-data-pxc-backup-etcd-0 -n $namespace -o yaml | grep -i "^[ ]*storageClassName" | tail -1 | awk -F ":" '{print $2}' | awk '{$1=$1}1'`
    echo "using storage class for mongo $sc"
    # update the storageclass in mongo.yaml
    sed -i 's|'storageClassName:.*'|'"storageClassName: $sc"'|g' mongo.yaml
    sed -i 's|'image:.*'|'"image: $image"'|g' mongo.yaml
    sed -i '/imagePullSecrets/{n;s/- name:.*/'"- name: $mongo_pull_secret"'/g}' mongo.yaml
    # Install mongoDB
    $kubectl_cmd apply -f ./mongo.yaml -n $namespace
    echo "Waiting for mongoDB to be in running state"
    for i in $(seq 1 100) ; do
        replicas=`$kubectl_cmd get statefulset  pxc-backup-mongodb-trial -n $namespace -o yaml | grep -i "^[ ]*readyReplicas" | tail -1 | awk -F ":" '{print $2}' | awk '{$1=$1}1'`
        if [ "$replicas" == "3" ]; then
            mongodeployed=true
            break
        else
            echo "mongodb datastore is not ready yet"
            sleep 10
        fi
    done
    if [ "$mongodeployed" == true ]; then
        $kubectl_cmd scale --replicas=0 deploy/px-backup -n $namespace
        sleep 10
        $kubectl_cmd cp ./migrationctl -n $namespace pxc-backup-mongodb-trial-0:/tmp
        $kubectl_cmd exec -it pxc-backup-mongodb-trial-0 -n $namespace -- /tmp/migrationctl
    else
        echo "Mongo deployment for trial run failed."
    fi
    # Delete all the resources of the trial mongoDB deployment.
    $kubectl_cmd delete sts pxc-backup-mongodb-trial -n $namespace
    $kubectl_cmd delete serviceaccount pxc-backup-mongodb-trial -n $namespace
    $kubectl_cmd delete secret pxc-backup-mongodb-trial -n $namespace
    $kubectl_cmd delete configmap pxc-backup-mongodb-trial-scripts -n $namespace
    $kubectl_cmd delete service pxc-backup-mongodb-trial-headless -n $namespace
    $kubectl_cmd delete pvc pxc-mongodb-data-pxc-backup-mongodb-trial-0 pxc-mongodb-data-pxc-backup-mongodb-trial-1 pxc-mongodb-data-pxc-backup-mongodb-trial-2 -n $namespace
    # scale up the px-backup deploy again
    $kubectl_cmd scale --replicas=1 deploy/px-backup -n $namespace
    sleep 10
    exit 0
}

do_rollback() {
    namespace=$1
    version=$2

    current_px_central_version="2.0.2"
    if [ `helm list -n px-backup | grep "px-central-2.0.1" | wc -l` -eq 1 ]; then
        current_px_central_version="2.0.1"
    elif [ `helm list -n px-backup | grep "px-central-2.0.0" | wc -l` -eq 1 ]; then
        current_px_central_version="2.0.0"
    fi

    # job_imagetag
    if [ $current_px_central_version == "2.0.2" ]; then
        job_image="pxcentral-onprem-post-setup"
        job_imagetag="2.0.2"
    elif [ $current_px_central_version == "2.0.1" ]; then
        job_image="pxcentral-onprem-post-setup"
        job_imagetag="2.0.1"
    elif [ $current_px_central_version == "2.0.0" ]; then
        job_image="pxcentral-onprem-post-setup"
        job_imagetag="2.0.0"
    else
        echo "Invalid px-central-chart version: $px_central_version , supported ones are : 2.0.2, 2.0.1 and 2.0.0"
    fi

    image="$job_registry/$job_repo/$job_image:$job_imagetag"
    backup_image="$job_registry/$job_repo/px-backup:$version"
    if [ $version == "1.2.4" ]; then
        uibackend_image="$job_registry/$job_repo/pxcentral-onprem-ui-backend:1.2.3"
        frontend_image="$job_registry/$job_repo/pxcentral-onprem-ui-frontend:1.2.3"
        lhbackend_image="$job_registry/$job_repo/pxcentral-onprem-ui-lhbackend:1.2.3"
    else
        uibackend_image="$job_registry/$job_repo/pxcentral-onprem-ui-backend:$version"
        frontend_image="$job_registry/$job_repo/pxcentral-onprem-ui-frontend:$version"
        lhbackend_image="$job_registry/$job_repo/pxcentral-onprem-ui-lhbackend:$version"
    fi
    jobspec='
apiVersion: batch/v1
kind: Job
metadata:
  name: pxcentral-post-install-hook
  namespace:
spec:
  activeDeadlineSeconds: 2400
  backoffLimit: 5
  completions: 1
  parallelism: 1
  template:
    metadata:
      labels:
        job-name: pxcentral-post-install-hook
    spec:
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: pxbackup/enabled
                operator: NotIn
                values:
                - "false"
      containers:
      - command:
        - python
        - -u
        - /pxcentral-post-install/pxc-post-setup.py
        env:
        - name: LOG_LEVEL
          value: INFO
        - name: UPDATE_ADMIN_USER_PROFILE
          value: "true"
        - name: PXC_NAMESPACE
          valueFrom:
            fieldRef:
              apiVersion: v1
              fieldPath: metadata.namespace
        - name: DEPLOYMENT_TYPE
          value: upgrade
        image: '$image'
        imagePullPolicy: Always
        name: pxcentral-post-setup
        resources: {}
        terminationMessagePath: /dev/termination-log
        terminationMessagePolicy: File
      dnsPolicy: ClusterFirst
      imagePullSecrets:
      - name: '$job_pull_secret'
      restartPolicy: Never
      schedulerName: default-scheduler
      securityContext:
        fsGroup: 1000
        runAsNonRoot: true
        runAsUser: 1000
      serviceAccount: pxcentral-apiserver
      serviceAccountName: pxcentral-apiserver
      terminationGracePeriodSeconds: 30
'
    # if rollback is set, set the datastore back to kvdb and
    # reset the images to rollback image version provided by user.
    # Reset image in px-backup deploy.
    $kubectl_cmd  patch  deploy px-backup -n $namespace -p "{\"spec\":{\"template\":{\"spec\":{\"containers\":[{\"command\":[\"/px-backup\",\"start\",\"--datastoreEndpoints=etcd:http://pxc-backup-etcd-0.pxc-backup-etcd-headless:2379,etcd:http://pxc-backup-etcd-1.pxc-backup-etcd-headless:2379,etcd:http://pxc-backup-etcd-2.pxc-backup-etcd-headless:2379\"],\"name\":\"px-backup\",\"image\":\"$backup_image\",\"env\":[{\"name\":\"PX_BACKUP_DEFAULT_DATASTORE\",\"value\":\"kvdb\"}]}]}}}}"
	$kubectl_cmd  patch  deploy pxcentral-backend -n $namespace -p "{\"spec\":{\"template\":{\"spec\":{\"containers\":[{\"name\":\"pxcentral-backend\",\"image\":\"$uibackend_image\"}]}}}}"
	$kubectl_cmd  patch  deploy pxcentral-frontend -n $namespace -p "{\"spec\":{\"template\":{\"spec\":{\"containers\":[{\"name\":\"pxcentral-frontend\",\"image\":\"$frontend_image\"}]}}}}"
	$kubectl_cmd  patch  deploy pxcentral-lh-middleware -n $namespace -p "{\"spec\":{\"template\":{\"spec\":{\"containers\":[{\"name\":\"pxcentral-lh-middleware\",\"image\":\"$lhbackend_image\"}]}}}}"
	$kubectl_cmd delete sa pxc-backup-mongodb -n $namespace
    $kubectl_cmd delete secret pxc-backup-mongodb -n $namespace
    $kubectl_cmd delete svc pxc-backup-mongodb-headless -n $namespace
    $kubectl_cmd delete cm pxc-backup-mongodb-scripts -n $namespace
    $kubectl_cmd delete sts pxc-backup-mongodb -n $namespace
    $kubectl_cmd delete pvc pxc-mongodb-data-pxc-backup-mongodb-0 pxc-mongodb-data-pxc-backup-mongodb-1 pxc-mongodb-data-pxc-backup-mongodb-2 -n $namespace

    # Rerunning of post install job
    # If post install job is present and jq is present, rerun the exising post install job
    # Else rerun the job with yaml spec.
    $kubectl_cmd get job pxcentral-post-install-hook -n $namespace
    job_exists=$?
    type jq
    jq_exists=$?
    if [ $job_exists -eq 0 ] && [ $jq_exists -eq 0 ]; then
        $kubectl_cmd get job pxcentral-post-install-hook -n $namespace -o json | jq 'del(.spec.selector)' | jq 'del(.spec.template.metadata.labels)' | $kubectl_cmd -n $namespace replace --force -f -
    else
        echo "Rerunning the post install job again by applying the job yaml"
        $kubectl_cmd delete job pxcentral-post-install-hook -n $namespace
        echo -e "$jobspec" | $kubectl_cmd -n $namespace apply -f -
    fi
    echo -e "
    Wait for job 'pxcentral-post-install-hook' status to be in 'Completed' state.
        kubectl get po --namespace $namespace -ljob-name=pxcentral-post-install-hook  -o wide
    "
    exit 0
}

# By default rollback will not be set to any version.
# rollback need to set, when the mongo migration failed and 
# decision is made to rollback to any older version to unblock the customer and 
# allow to continue with kvdb as datastore.
rollback=""
mongotrialmigration=false

if [ $# -eq 0 ]; then
    usage
    exit 1
fi

while [ $# -gt 0 ]; do
    case $1 in
        --helmrepo)
            echo "helm repo name = $2"
            helmrepo=$2
            shift
            shift
            ;;
        --namespace)
            echo "release namespace = $2"
            namespace=$2
            shift
            shift
            ;;
        --admin-password)
            echo "admin user password = $2"
            password=$2
            shift
            shift
            ;;
        --kubeconfig)
            echo "kubeconfig file = $2"
            kubeconfig=$2
            shift
            shift
            ;;
        --upgrade-version)
            echo "upgrade version = $2"
            px_central_version=$2
            shift
            shift
            ;;
        --rollback-version)
            echo "rollback version = $2"
            rollbackversion=$2
            shift
            shift
            ;;
        --mongo-trial-migration)
            echo "mongotrialmigration is set"
            mongotrialmigration=true
            shift
            ;;
        --air-gapped)
            echo "airgapped is set"
            airgapped=true
            shift
            ;;
        --helm-values-file)
            echo "helm values file = $2"
            helmvaluesfile=$2
            shift
            shift
            ;;
        --image-registry)
            echo "custom registry = $2"
            image_registry=$2
            shift
            shift
            ;;
        --image-repo)
            echo "custom repo = $2"
            image_repo=$2
            shift
            shift
            ;;
        --image-pull-secret)
            echo "custom repo pull secret = $2"
            image_pull_secret=$2
            shift
            shift
            ;;
        -h | --help)
            usage
            exit 0
            ;;
        *)
            echo
            echo "Invalid input '$1' "
            usage
            exit 1
            ;;
    esac
done

if [ "$namespace" == "" ]; then
    echo "--namespace is empty"
    usage
    exit 1
fi

if [ "$helmrepo" == "" ]; then
    echo "--helmrepo is empty"
    usage
    exit 1
fi

if [ "$mongotrialmigration" != true ] && [ -z "$rollbackversion" ]; then
    if [ "$password" == "" ]; then
        echo "--admin-password is empty"
        usage
        exit 1
    fi
fi

if [ "$kubeconfig" != "" ]; then
    kubectl_cmd="kubectl --kubeconfig $kubeconfig"
    helm_cmd="helm --kubeconfig $kubeconfig"
fi

# if airgapped option is set, then updates values.yaml is needed for upgrading.
if [ "$airgapped" == true ]; then
    if [ "$helmvaluesfile" == "" ]; then
        echo "--helm-values-file <values.yaml> file is required for upgrading in airgapped environments"
        usage
        exit 1
    fi
fi

if [ "$helmvaluesfile" != "" ]; then
    if [ ! -f $helmvaluesfile ]; then
        echo "Provided file $helmvaluesfile does not exist."
        usage
        exit 1
    fi
fi

if [ "$px_central_version" != "" ]; then
    if [ $px_central_version != "2.0.0" ] && [ $px_central_version != "2.0.1" ] && [ $px_central_version != "2.0.2" ]; then
        echo "upgrade-version can only be 2.0.2 or 2.0.1 or 2.0.0"
        usage
        exit 1
    fi
else
    echo "upgrade-version is empty"
    usage
    exit 1
fi

#invoke mongo trial migration, if mongotrainmigration option is set.
if [ "$mongotrialmigration" == true ]; then
    if [ ! -f "mongo.yaml" ] || [ ! -f "migrationctl" ]; then
        echo "Error: Please download mongo.yaml and migrationctl files to the current directory."
        echo "curl https://raw.githubusercontent.com/portworx/helm/master/single_chart_migration/mongo.yaml -o mongo.yaml"
        echo "curl https://raw.githubusercontent.com/portworx/helm/master/single_chart_migration/migrationctl -o migrationctl"
        exit 1
    fi
    if [ "$image_registry" != "" ]; then
        mongo_registry=$image_registry
    fi
    if [ "$image_repo" != "" ]; then
        mongo_repo=$image_repo
    fi
    if [ "$image_pull_secret" != "" ]; then
        mongo_pull_secret=$image_pull_secret
    fi
    mongo_trial_migration $namespace
fi

# If rollbackversion is set do the rollback
if [ ! -z "$rollbackversion" ]; then
    echo "Input rollback version:  $rollbackversion"
    if [ $rollbackversion != "1.2.2" ] && [ $rollbackversion != "1.2.3" ] && [ $rollbackversion != "1.2.4" ]; then
        echo "rollback version is $rollbackversion but rollback is supported only to 1.2.4, 1.2.3 or 1.2.2 version"
        exit 1
    fi
    if [ "$image_registry" != "" ]; then
        job_registry=$image_registry
    fi
    if [ "$image_repo" != "" ]; then
        job_repo=$image_repo
    fi
    if [ "$image_pull_secret" != "" ]; then
        job_pull_secret=$image_pull_secret
    fi

    do_rollback $namespace $rollbackversion
fi

echo -e "\nStep-1 : Looking for enabled features"
set_enabled_modules $namespace
echo "pxbackup: $pxbackup_enabled, pxmonitor: $pxmonitor_enabled, pxlicenseserver: $pxls_enabled"

echo -e "\nStep-2 : Searching the installed helm releases for the components"
find_releases $namespace
echo "pxbackup release: $pxbackup_release, pxmonitor release: $pxmonitor_release, pxlicenseserver release: $pxls_release"
verify_release $namespace $pxbackup_release

# Get all values in a single file
echo -e "\nStep-3 : Generating helm_values.yaml"
$helm_cmd get values $pxbackup_release --namespace $namespace -o yaml > helm_values.yaml
if [ "$pxmonitor_enabled" == true ]; then
    $helm_cmd get values $pxmonitor_release --namespace $namespace -o yaml >> helm_values.yaml
fi
if [ "$pxls_enabled" == true ]; then
    $helm_cmd get values $pxls_release --namespace $namespace -o yaml >> helm_values.yaml
fi

# Change the annotations
echo -e "\nStep-4 : Changing annotations of px-monitor and px-license-server components"
if [ "$pxmonitor_enabled" == true ]; then
    echo "Changing the annotations of existing px-monitor components"
    change_annotation "serviceaccount" "$saListMonitor"
    change_annotation "secret" "$secretListMonitor"
    change_annotation "configmap" "$cmListMonitor"
    change_annotation "pvc" "$pvcListMonitor"
    change_annotation "clusterrole" "$clusterroleListMonitor"
    change_annotation "clusterrolebinding" "$clusterrolebindingListMonitor"
    change_annotation "role" "$roleListMonitor"
    change_annotation "rolebinding" "$rolebindingListMonitor"
    change_annotation "service" "$svcListMonitor"
    change_annotation "statefulset" "$stsListMonitor"
    change_annotation "deployment" "$deploymentListMonitor"
    change_annotation "prometheus" "$prometheusMonitor"
    change_annotation "prometheusrule" "$prometheusruleMonitor"
    change_annotation "servicemonitor" "$servicemonitorListMonitor"
    delete_resource "statefulset" "$statefulsetListMonitorDelete"
    delete_resource "deployment" "$deploymentListMonitorDelete"
fi

if [ "$pxls_enabled" == true ]; then
    echo "Changing the annotations of existing px-license-server components"
    change_annotation "secret" "$secretListLS"
    change_annotation "configmap" "$cmListLS"
    change_annotation "service" "$svcListLS"
    change_annotation "deployment" "$deploymentListLS"
    delete_resource "deployment" "$deploymentListLSDelete"
fi

# Delete the post-install job
echo -e "\nStep-5 : Deleting post-install hook job before upgrade"
delete_job_cmd="$kubectl_cmd --namespace $namespace delete job $post_install_job"
echo $delete_job_cmd
$delete_job_cmd

# Do the upgrade
echo -e "\nStep-6 : Starting upgrade now"
# Version as global
upgrade_cmd="$helm_cmd --namespace $namespace upgrade $pxbackup_release $helmrepo/px-central --version $px_central_version"

if [ "$helmvaluesfile" == "" ]; then
    upgrade_cmd="$upgrade_cmd -f helm_values.yaml"
else
    upgrade_cmd="$upgrade_cmd -f $helmvaluesfile"
fi


if [ "$password" != "" ]; then
    upgrade_cmd="$upgrade_cmd --set oidc.centralOIDC.defaultPassword=$password"
fi

if [ "$pxbackup_enabled" == true ] && [ -z "$rollbackversion" ]; then
    upgrade_cmd="$upgrade_cmd --set pxbackup.enabled=true"
    # mongomigration will be set to incomplete by default, since this script will be called for upgrade only
    # Also etcd statefulset needs to be retained.
    upgrade_cmd="$upgrade_cmd --set pxbackup.mongoMigration=incomplete,pxbackup.datastore=mongodb,pxbackup.retainEtcd=true"
fi

if [ "$pxmonitor_enabled" == true ]; then
    upgrade_cmd="$upgrade_cmd --set pxmonitor.enabled=true"
    cassandra_pvc_check_cmd="$kubectl_cmd --namespace $namespace get pvc $cassandra_pvc_name"
    $cassandra_pvc_check_cmd
    if [ $? -eq 0 ]; then
        cassandra_pvc_size=`$kubectl_cmd --namespace $namespace get pvc $cassandra_pvc_name | grep -v NAME | tail -1 | awk '{print $4}'`
        upgrade_cmd="$upgrade_cmd --set persistentStorage.cassandra.storage=$cassandra_pvc_size"
    fi
fi
if [ "$pxls_enabled" == true ]; then
    upgrade_cmd="$upgrade_cmd --set pxlicenseserver.enabled=true"
fi

echo "upgrade command: $upgrade_cmd"
$upgrade_cmd
if [ $? -ne 0 ]; then
    echo "Upgrade to single chart with $px_central_version failed"
    exit 1
fi

echo "Deleting old stale jobs"
if [ "$pxmonitor_enabled" == true ]; then
    $kubectl_cmd --namespace $namespace delete job pxcentral-monitor-post-install-setup
fi
if [ "$pxls_enabled" == true ]; then
    $kubectl_cmd --namespace $namespace delete job pxcentral-license-ha-setup
fi

echo "Upgraded to single chart with $px_central_version version"
$helm_cmd list --namespace $namespace

echo -e "
#######################################################################################################
###                                                                                                 ###
### px-backup-ui service has been kept for backward compatibility but will soon be deprecated.      ###
### Please modify the ingress or routes which have been using px-backup-ui service                  ###
### to use px-central-ui service instead.                                                           ###
###                                                                                                 ###  
#######################################################################################################
"
exit 0

