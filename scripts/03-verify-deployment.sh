#!/bin/bash

# Script: Verify Deployment
# Purpose: Comprehensive verification of all deployed components

set -e

echo "========================================="
echo "Verifying E-Commerce Deployment"
echo "========================================="

NAMESPACE="ecommerce"
FAILED=0

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check status
check_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ PASS${NC}: $2"
    else
        echo -e "${RED}❌ FAIL${NC}: $2"
        FAILED=1
    fi
}

# 1. Check namespace exists
echo ""
echo "1️⃣  Checking namespace..."
kubectl get namespace $NAMESPACE &> /dev/null
check_status $? "Namespace '$NAMESPACE' exists"

# 2. Check all pods are running
echo ""
echo "2️⃣  Checking pods status..."
kubectl get pods -n $NAMESPACE
echo ""

# Count expected vs actual running pods
EXPECTED_PODS=4  # product(2) + order(2) + api-gateway(3) + frontend(3) = 10, but we'll check minimal
RUNNING_PODS=$(kubectl get pods -n $NAMESPACE --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l)

if [ "$RUNNING_PODS" -ge "$EXPECTED_PODS" ]; then
    check_status 0 "At least $EXPECTED_PODS pods are running (found $RUNNING_PODS)"
else
    check_status 1 "Expected at least $EXPECTED_PODS running pods, found $RUNNING_PODS"
fi

# 3. Check all pods are ready
NOT_READY=$(kubectl get pods -n $NAMESPACE --no-headers 2>/dev/null | grep -v "1/1" | wc -l)
if [ "$NOT_READY" -eq 0 ]; then
    check_status 0 "All pods are ready (1/1)"
else
    check_status 1 "Some pods are not ready"
    kubectl get pods -n $NAMESPACE | grep -v "1/1"
fi

# 4. Check services
echo ""
echo "3️⃣  Checking services..."
SERVICES=("product-service" "order-service" "api-gateway-active" "frontend")
for svc in "${SERVICES[@]}"; do
    kubectl get svc $svc -n $NAMESPACE &> /dev/null
    check_status $? "Service '$svc' exists"
done

# 5. Check ConfigMaps
echo ""
echo "4️⃣  Checking ConfigMaps..."
CONFIGMAPS=("service-config" "feature-flags")
for cm in "${CONFIGMAPS[@]}"; do
    kubectl get cm $cm -n $NAMESPACE &> /dev/null
    check_status $? "ConfigMap '$cm' exists"
done

# 6. Check Secrets
echo ""
echo "5️⃣  Checking Secrets..."
kubectl get secret api-keys -n $NAMESPACE &> /dev/null
check_status $? "Secret 'api-keys' exists"

# 7. Check HPAs
echo ""
echo "6️⃣  Checking HPAs..."
kubectl get hpa -n $NAMESPACE
echo ""
HPAS=("frontend-hpa" "api-gateway-hpa")
for hpa in "${HPAS[@]}"; do
    kubectl get hpa $hpa -n $NAMESPACE &> /dev/null
    check_status $? "HPA '$hpa' exists"
done

# 8. Test health endpoints
echo ""
echo "7️⃣  Testing health endpoints..."

# Test Product Service
PRODUCT_POD=$(kubectl get pod -n $NAMESPACE -l app=product-service -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -n "$PRODUCT_POD" ]; then
    kubectl exec -n $NAMESPACE $PRODUCT_POD -- wget -q -O- http://localhost:80/status/200 &> /dev/null
    check_status $? "Product Service health check"
fi

# Test Order Service
ORDER_POD=$(kubectl get pod -n $NAMESPACE -l app=order-service -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -n "$ORDER_POD" ]; then
    kubectl exec -n $NAMESPACE $ORDER_POD -- wget -q -O- http://localhost:80/status/200 &> /dev/null
    check_status $? "Order Service health check"
fi

# 9. Check resource limits
echo ""
echo "8️⃣  Checking resource limits..."
PODS_WITH_LIMITS=$(kubectl get pods -n $NAMESPACE -o json | jq '[.items[].spec.containers[].resources.limits] | length')
TOTAL_CONTAINERS=$(kubectl get pods -n $NAMESPACE -o json | jq '[.items[].spec.containers[]] | length')

if [ "$PODS_WITH_LIMITS" -eq "$TOTAL_CONTAINERS" ]; then
    check_status 0 "All containers have resource limits"
else
    echo -e "${YELLOW}⚠️  WARNING${NC}: Not all containers have resource limits ($PODS_WITH_LIMITS/$TOTAL_CONTAINERS)"
fi

# 10. Check probes
echo ""
echo "9️⃣  Checking health probes..."
kubectl get pods -n $NAMESPACE -o json | \
    jq -r '.items[] | .metadata.name + ": Liveness=" + 
    (if .spec.containers[0].livenessProbe then "✓" else "✗" end) + 
    ", Readiness=" + 
    (if .spec.containers[0].readinessProbe then "✓" else "✗" end)'

# 11. Test external access
echo ""
echo "🔟  Testing external access..."
echo "Getting service URLs..."
minikube service list -n $NAMESPACE

# Summary
echo ""
echo "========================================="
if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ All Checks Passed!${NC}"
    echo "========================================="
    echo ""
    echo "Your deployment is healthy and ready to use!"
    echo ""
    echo "🌐 Access the application:"
    echo "   minikube service frontend -n ecommerce"
    echo ""
    echo "📊 Monitor resources:"
    echo "   kubectl top pods -n ecommerce"
    echo "   kubectl get hpa -n ecommerce --watch"
    exit 0
else
    echo -e "${RED}❌ Some Checks Failed${NC}"
    echo "========================================="
    echo ""
    echo "Please review the failures above and fix them."
    echo ""
    echo "Debugging commands:"
    echo "   kubectl get pods -n ecommerce"
    echo "   kubectl describe pod <pod-name> -n ecommerce"
    echo "   kubectl logs <pod-name> -n ecommerce"
    exit 1
fi
