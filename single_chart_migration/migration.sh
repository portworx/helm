#!/bin/bash

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

px_central_version="1.3.0"
pxbackup_enabled=false
pxmonitor_enabled=false
pxls_enabled=false

frontend_deployment="pxcentral-frontend"
cortex_nginx_deployment="pxcentral-cortex-nginx"
ls_configmap="pxcentral-ls-configmap"
post_install_job="pxcentral-post-install-hook"

usage()
{
   echo ""
   echo "Usage: $0 --namespace <namespace> --helmrepo <helm repo name> --kubeconfig <kubeconfig file name> "
   echo -e "\t--namespace <namespace> namespace in which px-central charts are installed"
   echo -e "\t--helmrepo <helm repo name for px-central components> helm repo name , can get with helm repo list command"
   echo -e "\t--kubeconfig <kubeconfig file path> kubeconfig file to set the context, Optional"
   exit 1 # Exit script after printing help
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

    cmd="$kubectl_cmd -n $namespace annotate $resourcetype $resource "meta.helm.sh/release-name=$pxbackup_release" --overwrite"
    echo -e $cmd
    $cmd
    if [ $? -ne 0 ]; then
        echo -e "Failed: $cmd, exiting from the update script"
        exit 1
    fi
    echo -e "Success: $cmd"
}

delete_resource() {
    resourcetype=$1
    resource=$2

    cmd="$kubectl_cmd -n $namespace delete $resourcetype $resource"
    echo -e $cmd
    $cmd
    if [ $? -ne 0 ]; then
        echo -e "Faile: $cmd, exiting from the update script"
        exit 1
    fi
    echo -e "Success: $cmd"
}

set_enabled_modules() {
    namespace=$1
    backup_match=`$kubectl_cmd --namespace $namespace describe cm pxcentral-ui-configmap | grep -A 2 FRONTEND_ENABLED_MODULES | tail -1 | grep -c PXBACKUP`
    if [ $backup_match -gt 0 ] ; then
        pxbackup_enabled=true
    fi

    monitor_match=`$kubectl_cmd --namespace $namespace describe cm pxcentral-ui-configmap | grep -A 2 FRONTEND_ENABLED_MODULES | tail -1 | grep -c PXMETRICS`
    if [ $monitor_match -gt 0 ] ; then
        pxmonitor_enabled=true
    fi

    ls_match=`$kubectl_cmd --namespace $namespace describe cm pxcentral-ui-configmap | grep -A 2 FRONTEND_ENABLED_MODULES | tail -1 | grep -c PXLICENSE`
    if [ $ls_match -gt 0 ] ; then
        pxls_enabled=true
    fi

}

find_releases() {
    namespace=$1
    if [ "$pxbackup_enabled" == true ]; then
        # Finding px-backup release name from frontend deployment as px-backup may not be installed
        pxbackup_release=`$kubectl_cmd --namespace $namespace get deployment $frontend_deployment  -o yaml | grep -w "release-name" | tail -1 | awk -F ":" '{print $2}' | awk '{$1=$1}1'`
        if [ "$pxbackup_release" == "" ]; then
            echo "px-backup is enabled but could not find the px-backup release"
            exit 1
        fi
    fi
    if [ "$pxmonitor_enabled" == true ]; then
        pxmonitor_release=`$kubectl_cmd --namespace $namespace get deployment $cortex_nginx_deployment  -o yaml | grep -w "release-name" | tail -1 | awk -F ":" '{print $2}' | awk '{$1=$1}1'`
        if [ "$pxmonitor_release" == "" ]; then
            echo "px-monitor is enabled but could not find the px-monitor release"
            exit 1
        fi
    fi

    # Checking configmap instead of deployment for licenseserver as part of upgrade we have to delete ls deployment 
    # And in case the script has to run again, then it will not get license-server release name.
    if [ "$pxls_enabled" == true ]; then
        pxls_release=`$kubectl_cmd --namespace $namespace get configmap $ls_configmap  -o yaml | grep -w "release-name" | tail -1 | awk -F ":" '{print $2}' | awk '{$1=$1}1'`
        if [ "$pxls_release" == "" ]; then
            echo "px-license-server is enabled but could not find the px-license-server release"
            exit 1
        fi
    fi
}


for i in $@
do
    case $i in
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
        --kubeconfig)
            echo "kubeconfig file = $2"
            kubeconfig=$2
            shift
            shift
            ;;
    esac
done

if [ "$namespace" == "" ] || [ "$helmrepo" == "" ]; then
    usage
    exit 1
fi

if [ "$kubeconfig" != "" ]; then
    kubectl_cmd="kubectl --kubeconfig $kubeconfig"
    helm_cmd="helm --kubeconfig $kubeconfig"
fi

echo "Step-1 : Finding out the enabled modules"
set_enabled_modules $namespace
echo "pxbackup: $pxbackup_enabled, pxmonitor: $pxmonitor_enabled, pxlicenseserver: $pxls_enabled"

echo "Step-2 : Finding the installed releases for the components"
find_releases $namespace
echo "pxbackup release: $pxbackup_release, pxmonitor release: $pxmonitor_release, pxlicenseserver release: $pxls_release"

# Get all values in a single file
echo "Step-3 : Putting the values in helm_values.yaml file"
$helm_cmd get values $pxbackup_release --namespace $namespace -o yaml > helm_values.yaml
if [ "$pxmonitor_enabled" == true ]; then
    $helm_cmd get values $pxmonitor_release --namespace $namespace -o yaml >> helm_values.yaml
fi
if [ "$pxls_enabled" != "" ]; then
    $helm_cmd get values $pxls_release --namespace $namespace -o yaml >> helm_values.yaml
fi

# Change the annotations
echo "Step-4 : Changing annotations of px-monitor and px-license-server componets if they have been installed"
if [ "$pxmonitor_enabled" != "" ]; then
    echo "Changing the annotations of existing px-monitor componenets"
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

if [ "$pxls_enabled" != "" ]; then
    echo "Changing the annotations of existing px-license-server componenets"
    change_annotation "secret" "$secretListLS"
    change_annotation "configmap" "$cmListLS"
    change_annotation "service" "$svcListLS"
    change_annotation "deployment" "$deploymentListLS"
    delete_resource "deployment" "$deploymentListLSDelete"
fi

# Delete the post-install job
echo "Step-5 : Deleting post-install hook job before upgrade"
delete_job_cmd="$kubectl_cmd --namespace $namespace delete job $post_install_job"
echo $delete_job_cmd
$delete_job_cmd

# Do the upgrade
echo "Step-6 : Going to do upgrade now"
# Version as global
upgrade_cmd="$helm_cmd --namespace $namespace upgrade $pxbackup_release $helmrepo/px-central --version $px_central_version -f helm_values.yaml"

if [ "$pxbackup_enabled" == true ]; then
    upgrade_cmd="$upgrade_cmd --set pxbackup.enabled=true"
fi
if [ "$pxmonitor_enabled" == true ]; then
    upgrade_cmd="$upgrade_cmd --set pxmonitor.enabled=true"
fi
if [ "$pxls_enabled" == true ]; then
    upgrade_cmd="$upgrade_cmd --set pxlicenseserver.enabled=true"
fi

echo "upgrade command: $upgrade_cmd"
$upgrade_cmd
if [ $? != 0 ]; then
    echo "Upgrade to single chart with 1.3.0 failed"
    exit 1
fi

echo "Successfully upgraded to single chart with 1.3.0 version"
$helm_cmd list --namespace $namespace
exit 0

