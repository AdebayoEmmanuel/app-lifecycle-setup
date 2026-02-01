#!/bin/bash

# Test: Health Check Verification
# Purpose: Verify all services have proper health checks configured

set -e

NAMESPACE="ecommerce"
FAILED=0

echo "========================================="
echo "Health Check Verification Test"
echo "========================================="

# Function to check probe
check_probe() {
    local pod=$1
    local probe_type=$2
    
    result=$(kubectl get pod $pod -n $NAMESPACE -o json | \
        jq -r ".spec.containers[0].${probe_type}Probe")
    
    if [ "$result" != "null" ]; then
        echo "✅ $pod has $probe_type probe"
        return 0
    else
        echo "❌ $pod missing $probe_type probe"
        FAILED=1
        return 1
    fi
}

# Get all pods
echo ""
echo "Checking health probes for all pods..."
echo ""

PODS=$(kubectl get pods -n $NAMESPACE -o jsonpath='{.items[*].metadata.name}')

for pod in $PODS; do
    echo "Checking $pod:"
    check_probe $pod "liveness"
    check_probe $pod "readiness"
    
    # Check if startup probe exists (optional)
    startup=$(kubectl get pod $pod -n $NAMESPACE -o json | \
        jq -r ".spec.containers[0].startupProbe")
    if [ "$startup" != "null" ]; then
        echo "✅ $pod has startup probe"
    else
        echo "ℹ️  $pod has no startup probe (optional)"
    fi
    echo ""
done

# Test actual health endpoints
echo "========================================="
echo "Testing Health Endpoints"
echo "========================================="
echo ""

# Test each service
SERVICES=("product-service" "order-service")
for svc in "${SERVICES[@]}"; do
    echo "Testing $svc..."
    POD=$(kubectl get pod -n $NAMESPACE -l app=$svc -o jsonpath='{.items[0].metadata.name}')
    
    if [ -n "$POD" ]; then
        if kubectl exec -n $NAMESPACE $POD -- wget -q -O- http://localhost:80/status/200 &> /dev/null; then
            echo "✅ $svc health endpoint responding"
        else
            echo "❌ $svc health endpoint not responding"
            FAILED=1
        fi
    fi
done

# Test API Gateway health
echo "Testing api-gateway..."
API_POD=$(kubectl get pod -n $NAMESPACE -l app=api-gateway -o jsonpath='{.items[0].metadata.name}')
if [ -n "$API_POD" ]; then
    if kubectl exec -n $NAMESPACE $API_POD -- wget -q -O- http://localhost:80/health &> /dev/null; then
        echo "✅ api-gateway health endpoint responding"
    else
        echo "❌ api-gateway health endpoint not responding"
        FAILED=1
    fi
fi

echo ""
echo "========================================="
if [ $FAILED -eq 0 ]; then
    echo "✅ All Health Checks Passed!"
    exit 0
else
    echo "❌ Some Health Checks Failed"
    exit 1
fi
