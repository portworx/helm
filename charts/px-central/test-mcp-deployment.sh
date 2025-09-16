#!/bin/bash

# Test script for MCP deployment
# This script validates the MCP helm chart configuration

set -e

echo "🚀 Testing MCP Deployment Configuration"
echo "========================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print status
print_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ $2${NC}"
    else
        echo -e "${RED}❌ $2${NC}"
        exit 1
    fi
}

print_info() {
    echo -e "${YELLOW}ℹ️  $1${NC}"
}

# Test 1: Validate helm template with MCP disabled
print_info "Test 1: Validating helm template with MCP disabled"
helm template px-central . --set pxbackup.enabled=true --set pxbackup.mcp.enabled=false > /tmp/mcp-disabled.yaml
if ! grep -q "mcp" /tmp/mcp-disabled.yaml; then
    print_status 0 "MCP components not present when disabled"
else
    print_status 1 "MCP components found when disabled"
fi

# Test 2: Validate helm template with MCP enabled
print_info "Test 2: Validating helm template with MCP enabled"
helm template px-central . -f mcp-test-values.yaml > /tmp/mcp-enabled.yaml

# Check for MCP service
if grep -q "name: px-backup-mcp" /tmp/mcp-enabled.yaml; then
    print_status 0 "MCP NodePort service created"
else
    print_status 1 "MCP NodePort service not found"
fi

# Check for MCP port in main service
if grep -q "port: 8080" /tmp/mcp-enabled.yaml && grep -q "name: mcp-server" /tmp/mcp-enabled.yaml; then
    print_status 0 "MCP port added to main service"
else
    print_status 1 "MCP port not found in main service"
fi

# Check for MCP environment variables
if grep -q "MCP_ENABLED" /tmp/mcp-enabled.yaml && grep -q "MCP_PORT" /tmp/mcp-enabled.yaml; then
    print_status 0 "MCP environment variables present"
else
    print_status 1 "MCP environment variables missing"
fi

# Check for MCP command line arguments
if grep -q "\-\-mcp-enabled=true" /tmp/mcp-enabled.yaml && grep -q "\-\-mcp-port=8080" /tmp/mcp-enabled.yaml; then
    print_status 0 "MCP command line arguments present"
else
    print_status 1 "MCP command line arguments missing"
fi

# Check for container port
if grep -q "containerPort: 8080" /tmp/mcp-enabled.yaml; then
    print_status 0 "MCP container port configured"
else
    print_status 1 "MCP container port missing"
fi

# Check for NodePort configuration
if grep -q "nodePort: 30080" /tmp/mcp-enabled.yaml; then
    print_status 0 "NodePort 30080 configured"
else
    print_status 1 "NodePort 30080 not found"
fi

# Test 3: Validate values.yaml structure
print_info "Test 3: Validating values.yaml MCP configuration"
if grep -q "mcp:" values.yaml; then
    print_status 0 "MCP configuration section exists in values.yaml"
else
    print_status 1 "MCP configuration section missing in values.yaml"
fi

# Test 4: Check documentation
print_info "Test 4: Validating documentation"
if [ -f "MCP-DEPLOYMENT.md" ]; then
    print_status 0 "MCP deployment documentation exists"
else
    print_status 1 "MCP deployment documentation missing"
fi

if [ -f "mcp-test-values.yaml" ]; then
    print_status 0 "MCP test values file exists"
else
    print_status 1 "MCP test values file missing"
fi

# Test 5: Validate YAML syntax
print_info "Test 5: Validating YAML syntax"
if helm template px-central . -f mcp-test-values.yaml > /dev/null 2>&1; then
    print_status 0 "Helm template generation passed"
else
    print_status 1 "Helm template generation failed"
fi

# Cleanup
rm -f /tmp/mcp-enabled.yaml /tmp/mcp-disabled.yaml

echo ""
echo -e "${GREEN}🎉 All MCP deployment tests passed!${NC}"
echo ""
echo "📋 Next Steps:"
echo "1. Deploy using: helm install px-central . -f mcp-test-values.yaml -n px-central --create-namespace"
echo "2. Test MCP endpoint: curl http://<node-ip>:30080/health"
echo "3. List tools: curl http://<node-ip>:30080/tools"
echo ""
echo "📖 For detailed instructions, see MCP-DEPLOYMENT.md"
