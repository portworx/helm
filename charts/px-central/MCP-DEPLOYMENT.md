# MCP (Model Context Protocol) Deployment Guide

This document describes how to deploy px-backup with MCP server functionality enabled for AI agent integration.

## Overview

The MCP server provides a standardized interface for AI agents to interact with px-backup functionality. It exposes backup management operations through a JSON-RPC 2.0 API.

## Configuration

### Basic MCP Configuration

Add the following to your values.yaml or use helm set commands:

```yaml
pxbackup:
  enabled: true
  mcp:
    enabled: true
    port: 8080
    address: "0.0.0.0"
    authRequired: true
    serviceType: "NodePort"
    nodePort: 30080
```

### Advanced Configuration

```yaml
pxbackup:
  mcp:
    enabled: true
    port: 8080
    address: "0.0.0.0"
    authRequired: true
    serviceType: "NodePort"
    nodePort: 30080
    # Optional TLS configuration
    tlsCertFile: "/path/to/cert.pem"
    tlsKeyFile: "/path/to/key.pem"
```

## Deployment Options

### Option 1: NodePort Service (Recommended for Testing)

```bash
helm install px-central . \
  --set pxbackup.enabled=true \
  --set pxbackup.mcp.enabled=true \
  --set pxbackup.mcp.serviceType=NodePort \
  --set pxbackup.mcp.nodePort=30080 \
  -n px-central --create-namespace
```

### Option 2: Using Values File

```bash
# Create custom values file
cat > mcp-values.yaml << EOF
pxbackup:
  enabled: true
  mcp:
    enabled: true
    serviceType: "NodePort"
    nodePort: 30080
EOF

# Deploy with custom values
helm install px-central . -f mcp-values.yaml -n px-central --create-namespace
```

### Option 3: LoadBalancer Service (Cloud Environments)

```bash
helm install px-central . \
  --set pxbackup.enabled=true \
  --set pxbackup.mcp.enabled=true \
  --set pxbackup.mcp.serviceType=LoadBalancer \
  -n px-central --create-namespace
```

## Accessing MCP Server

### Internal Access (from within cluster)
- Service: `px-backup:8080`
- Health: `http://px-backup:8080/health`
- Tools: `http://px-backup:8080/tools`

### External Access (NodePort)
- Health: `http://<node-ip>:30080/health`
- Tools: `http://<node-ip>:30080/tools`
- JSON-RPC: `POST http://<node-ip>:30080/`

## Testing MCP Functionality

### 1. Health Check
```bash
curl http://<node-ip>:30080/health
```

### 2. List Available Tools
```bash
curl http://<node-ip>:30080/tools
```

### 3. JSON-RPC Tool Call
```bash
curl -X POST http://<node-ip>:30080/ \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "tools/list",
    "params": {}
  }'
```

## Available MCP Tools

- `list_backups` - List backup objects
- `list_clusters` - List cluster information
- `list_backup_locations` - List backup locations
- `inspect_cluster_health` - Get cluster health details
- `get_backup_trends` - Get backup trend analytics

## Security Considerations

1. **Authentication**: MCP server uses the same authentication as px-backup
2. **Network Security**: Consider using TLS in production
3. **RBAC**: Existing px-backup RBAC applies to MCP operations
4. **Firewall**: Ensure port 30080 (or custom nodePort) is accessible

## Troubleshooting

### Check MCP Server Status
```bash
kubectl logs -n px-central deployment/px-backup | grep -i mcp
```

### Verify Service Configuration
```bash
kubectl get svc -n px-central px-backup-mcp
```

### Test Connectivity
```bash
kubectl port-forward -n px-central svc/px-backup-mcp 8080:8080
curl http://localhost:8080/health
```

## Configuration Reference

| Parameter | Default | Description |
|-----------|---------|-------------|
| `pxbackup.mcp.enabled` | `false` | Enable MCP server |
| `pxbackup.mcp.port` | `8080` | MCP server port |
| `pxbackup.mcp.address` | `"0.0.0.0"` | Bind address |
| `pxbackup.mcp.authRequired` | `true` | Require authentication |
| `pxbackup.mcp.serviceType` | `"NodePort"` | Service type |
| `pxbackup.mcp.nodePort` | `30080` | NodePort number |
| `pxbackup.mcp.tlsCertFile` | `""` | TLS certificate file |
| `pxbackup.mcp.tlsKeyFile` | `""` | TLS private key file |
