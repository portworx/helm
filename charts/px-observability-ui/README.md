# px-observability-ui Helm chart

Deploys `px-observability-ui`, optionally bundled with PX Cache Agent.

## Install

For non-OCP clusters:

```bash
helm install px-observability portworx/px-observability-ui \
  --namespace portworx
```

`--namespace` must be namespace where Portworx is installed.

For OCP clusters:

1. Enable the Portworx Dynamic Plugin by following the instructions [here](https://docs.portworx.com/portworx-enterprise/platform/configure-portworx-components/enable-ocp-plugin).
2. Install the Helm Chart with the following command:

```bash
helm install px-observability portworx/px-observability-ui \
  --namespace portworx \
  --set cacheAgent.enabled=false \
  --set cacheAgent.service.name=px-cache-agent-service \
  --set cacheAgent.serviceAccount.name=px-cache-agent \
  --set cacheAgent.prometheusEndpoint="https://thanos-querier.openshift-monitoring.svc.cluster.local:9091"
```

`--namespace` must be namespace where Portworx is installed.

### Resource naming

All resources created by this chart are prefixed with `pxo-` (for example `pxo-observability-ui`,
`pxo-cache-agent`, `pxo-cache-agent-service`) so they don't conflict with resources already
in the cluster.

When `cacheAgent.enabled=false`, the UI connects to an existing PX Cache Agent. The defaults are
`pxo-` prefixed and won't match it, so set `cacheAgent.service.name` and
`cacheAgent.serviceAccount.name` to the existing agent's actual names (as in the OCP command above).

The 5 `agent.multicluster.portworx.com` CRDs are cluster-scoped and cannot be prefixed. If another
PX Cache Agent install already owns them, set `--set cacheAgent.installCRDs=false`.

Upgrading from a release that used the old unprefixed names is not supported with `helm upgrade`
(Deployment selector labels are immutable); uninstall and reinstall instead.


### OCP Route

On OpenShift, add `--set route.enabled=true` to expose the UI via a Route; elsewhere use
`kubectl port-forward` to access the UI.

## Values

| Key | Default | Description |
|---|---|---|
| `ui.image.repository` | `pure-artifactory.dev.purestorage.com:443/px-docker-dev-virtual/gsadhani/px-observability-ui` | UI+authproxy image |
| `ui.image.tag` | `latest` | |
| `ui.image.pullPolicy` | `Always` | |
| `ui.replicas` | `1` | |
| `ui.resources` | 75m/160Mi req, 300m/320Mi limit | |
| `ui.serviceAccount.create` | `true` | |
| `ui.service.type` | `ClusterIP` | Set to `NodePort`/`LoadBalancer` for external access outside OpenShift (where `route.enabled` is used instead) |
| `ui.service.port` | `8080` | |
| `route.enabled` | `false` | OpenShift Route (edge TLS) for the UI Service |
| `cacheAgent.enabled` | `true` | Install PX Cache Agent's Deployment/Service/RBAC/CRDs as part of this release |
| `cacheAgent.installCRDs` | `true` | Install the 5 `agent.multicluster.portworx.com` DR/multicluster CRDs (only when `cacheAgent.enabled`) |
| `cacheAgent.image.repository` | *(required)* | No safe default — see Context in the implementation plan |
| `cacheAgent.image.tag` | *(required)* | |
| `cacheAgent.serviceAccount.name` | `pxo-cache-agent` | Also used by the UI's authproxy (`SERVICE_ACCOUNT_NAME`) and its token-minter Role, even when `cacheAgent.enabled=false` |
| `cacheAgent.service.name` | `pxo-cache-agent-service` | Also used by the UI's authproxy (`UPSTREAM_URL`) |
| `cacheAgent.prometheusEndpoint` | `http://px-prometheus.portworx.svc.cluster.local:9090` | Passed as `--prometheus-endpoint` |
| `cacheAgent.resources` | 100m/64Mi req, 400m/2Gi limit | |

