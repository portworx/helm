# Backup image CVE and schedule posture POC

This branch packages the existing POC with the `px-central` 3.2.0-staging
chart. It switches PX-Backup, middleware, and frontend to their feature
images, then adds a separate Trivy worker with a 10 GiB cache PVC, Service,
NetworkPolicy, and shared service token. The worker does not need backup
location credentials or a Docker account for public-image scans.

The scanner is enabled when `pxbackup.enabled=true`. Image CVE scans are
started manually from backup details. Completed namespace backups in a backup
schedule receive configuration assessments automatically when
`pxbackup.imageSecurity.schedulePostureEnabled=true`. No Stork chart or API
service change is needed.

## New installation

Use the existing site values required for a 3.2.0-staging PX-Backup install.
They must configure PX-Backup, storage, ingress, credentials, and any image
pull Secret required by the cluster. Clone this feature branch, then run the
chart from that checkout:

```bash
git clone --branch hackathon/backup-image-cve git@github.com:portworx/helm.git
cd helm
```

From the repository root:

```bash
helm install px-central ./charts/px-central \
  --namespace px-backup --create-namespace \
  -f /path/to/site-values.yaml \
  --set pxbackup.enabled=true \
  --wait --timeout 15m
```

The feature image tags and scanner settings are defaults in this branch. They
use `imagePullPolicy: Always` and do not pin image digests. The worker PVC
uses `pxbackup.imageSecurity.cache.storageClassName` if set, otherwise
`persistentStorage.storageClassName`, then the cluster's default StorageClass.
Its cache requests 10 GiB and its temporary files use a 5 GiB `emptyDir`.
If site values set a global `images.registry` or `images.repo`, those override
the per-image feature locations; verify the resulting four image references
with `helm template` before installing.
The init container must reach the Trivy DB registry at first startup; image
scans need access to public Docker Hub images.

For a new install, Helm creates a random
`px-backup-image-scanner-token` Secret. On later Helm upgrades it reads and
reuses the existing token, so upgrades do not rotate it accidentally.

## Upgrade an existing staging release

Use the same release name, namespace, kubeconfig, and site values as the
existing 3.2.0-staging installation. `--reuse-values` retains site
configuration; the overlay explicitly supplies the new worker settings and
replaces the old image values. Follow any ordinary pre-upgrade steps required
for your release, including the post-install Job cleanup described in this
chart's [upgrade guide](README.md#upgrading-the-chart).

```bash
helm upgrade px-central ./charts/px-central \
  --namespace px-backup --reuse-values \
  -f ./charts/px-central/hackathon-image-cve.values.yaml \
  --wait --timeout 15m
```

If the cluster already has a manually created scanner token, add
`--set-string pxbackup.imageSecurity.existingTokenSecretName=px-backup-image-scanner-token`.
Helm then mounts that Secret without trying to create another one. The Secret
must contain a `token` key. An existing manually installed worker Deployment,
Service, PVC, or NetworkPolicy also needs Helm ownership migration before this
upgrade; a clean staging release without those POC resources does not.
Do not delete an existing scanner PVC merely to make the upgrade pass.

## Verify the installation

```bash
kubectl -n px-backup get deployment px-backup px-backup-image-scanner \
  pxcentral-lh-middleware pxcentral-frontend
kubectl -n px-backup get pvc px-backup-image-scanner-cache
kubectl -n px-backup get pods -l app=px-backup-image-scanner
```

All four Deployments should be ready and the scanner cache PVC should be
Bound. Make a completed namespace backup with public Linux/amd64 images,
open its details, and select **Scan images**. For configuration history,
create a namespace backup schedule and let it produce at least two completed
points.

The frontend and middleware runners publish their feature tags to private
Docker Hub. The PX-Backup branch’s **Publish hackathon UI images to Pure
Artifactory** workflow mirrors those tags into `px-docker-prod-local/portworx`,
which this chart uses directly. After publishing a new UI or middleware image,
rerun its most recent successful mirror job, then restart the relevant Deployment:

```bash
gh run list --repo pure-px/px-backup --branch hackathon/backup-image-cve \
  --workflow hackathon-mirror.yaml --limit 5
gh run rerun MIRROR_RUN_ID --repo pure-px/px-backup
gh run watch MIRROR_RUN_ID --repo pure-px/px-backup --exit-status
kubectl -n px-backup rollout restart deployment/pxcentral-frontend
```

Use `pxcentral-lh-middleware` when refreshing middleware. The rerun pulls the
current mutable tags. A new branch-only workflow may not appear in GitHub's
manual-dispatch UI until it exists on the default branch; rerunning the existing
job works with this feature branch. This avoids stale
Docker Hub proxy manifests while retaining mutable tags and Always pulls.
The PX-Backup and volume-scanner builders publish to Artifactory directly.

## Manual PXD/S3 volume malware assessment

This branch also enables **Scan volume data** in backup Show Details. It supports
successful namespace backups with only native `pxd` filesystem PVC backups on an
S3 or S3-compatible location. It restores each PVC to the registered source
cluster, runs a separate offline ClamAV/YARA Job with read-only data, persists
findings, and cleans up the temporary Job, namespace and restored volume. The
existing CVE schedule can remain suspended; volume scans are manual.

The scanner image is `portworx/px-backup-volume-scanner:hackathon-backup-image-cve`
through Pure Artifactory. Its signature database is bundled at build time; the
report records engine versions, database/rule hashes and the actual image ID.
Rebuild to refresh signatures. There is no permanent malware worker pod or PVC.

First-release bounds: four PVCs / 20 GiB total restored capacity; one active scan
at a time; 20-minute restore and 10-minute Job deadlines per PVC; 100 MiB per file,
100,000 filesystem entries and 1,000 findings per volume. Skips or engine errors
make the assessment incomplete. The YARA rules are explicitly labelled demo
indicators; replace with a vetted ruleset before production use.

Start/cancel requires PX-Backup super administrator. Readers need source-backup
access. The registered cluster credential must be able to restore PVCs and manage
temporary namespaces, Jobs, NetworkPolicies, PVCs, and read PVs and Pod logs.
A deny-all NetworkPolicy is installed before scanning; the CNI must enforce it.
The scanner receives no application Secret or Kubernetes service-account token.
A configured registry pull Secret is used only by the kubelet.

If Pure Artifactory requires authentication on the target cluster, create its
ordinary image pull Secret in the PX-Backup installation namespace, then use:

```bash
helm upgrade px-central ./charts/px-central -n px-backup --reuse-values \
  -f ./charts/px-central/hackathon-image-cve.values.yaml \
  --set-string pxbackup.volumeSecurity.pullSecretName=artifactory-pull \
  --wait --timeout 15m
```

Leave `pullSecretName` empty for anonymous registry pulls. To disable only this
feature set `pxbackup.volumeSecurity.enabled=false`. Mutable tags use Always;
restart PX-Backup, frontend and middleware after their updated tags are published.

Expanded backups show **Volume findings**. Show Details lists paths, engines,
rule IDs, hashes, test-indicator labels, provenance and cleanup state. The restore
wizard requests acknowledgement for any detected files. No detections is not a
safety guarantee; unscanned and partial results remain explicit.

Validated on a-116: the original native S3 backup detected three harmless test
files (four findings across ClamAV/YARA). A newer backup after removing those
fixtures had no detections, using the same scanner profile. Manual cancellation,
backend restart recovery and restored-volume cleanup also passed.

Feature frontend, middleware, backend and volume-scanner references use
`px-docker-prod-local` after direct CI publishing, to avoid stale manifests
from the virtual repository's Docker Hub proxy. Existing public dependency
images can continue through their configured repositories.
