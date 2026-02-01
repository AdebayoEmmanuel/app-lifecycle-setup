#!/bin/bash

# Test: Deployment Strategy Verification
# Purpose: Verify canary and blue-green deployment strategies are configured correctly

set -e

NAMESPACE="ecommerce"
FAILED=0

echo "========================================="
echo "Deployment Strategy Verification Test"
echo "========================================="

# Test 1: Verify Canary Setup (Frontend)
echo ""
echo "1️⃣  Verifying Canary Deployment Setup (Frontend)..."

# Check both v1 and v2 deployments exist
if kubectl get deployment frontend-v1 -n $NAMESPACE &> /dev/null; then
    echo "✅ frontend-v1 deployment exists"
else
    echo "❌ frontend-v1 deployment not found"
    FAILED=1
fi

if kubectl get deployment frontend-v2 -n $NAMESPACE &> /dev/null; then
    echo "✅ frontend-v2 deployment exists"
else
    echo "❌ frontend-v2 deployment not found"
    FAILED=1
fi

# Verify service selector (should select both versions)
SERVICE_SELECTOR=$(kubectl get svc frontend -n $NAMESPACE -o jsonpath='{.spec.selector}' | jq -r '.version // "none"')
if [ "$SERVICE_SELECTOR" = "none" ]; then
    echo "✅ Frontend service selector is version-agnostic (correct for canary)"
else
    echo "❌ Frontend service selector includes version (incorrect for canary)"
    FAILED=1
fi

# Test 2: Verify Blue-Green Setup (API Gateway)
echo ""
echo "2️⃣  Verifying Blue-Green Deployment Setup (API Gateway)..."

# Check blue and green deployments exist
if kubectl get deployment api-gateway-blue -n $NAMESPACE &> /dev/null; then
    echo "✅ api-gateway-blue deployment exists"
else
    echo "❌ api-gateway-blue deployment not found"
    FAILED=1
fi

if kubectl get deployment api-gateway-green -n $NAMESPACE &> /dev/null; then
    echo "✅ api-gateway-green deployment exists"
else
    echo "❌ api-gateway-green deployment not found"
    FAILED=1
fi

# Check separate services for blue and green
if kubectl get svc api-gateway-blue -n $NAMESPACE &> /dev/null; then
    echo "✅ api-gateway-blue service exists"
else
    echo "❌ api-gateway-blue service not found"
    FAILED=1
fi

if kubectl get svc api-gateway-green -n $NAMESPACE &> /dev/null; then
    echo "✅ api-gateway-green service exists"
else
    echo "❌ api-gateway-green service not found"
    FAILED=1
fi

# Check active service
if kubectl get svc api-gateway-active -n $NAMESPACE &> /dev/null; then
    echo "✅ api-gateway-active service exists"
    
    ACTIVE_VERSION=$(kubectl get svc api-gateway-active -n $NAMESPACE -o jsonpath='{.spec.selector.version}')
    echo "   Currently active: $ACTIVE_VERSION"
else
    echo "❌ api-gateway-active service not found"
    FAILED=1
fi

# Test 3: Verify Rolling Update Strategy (Backend Services)
echo ""
echo "3️⃣  Verifying Rolling Update Strategy (Backend Services)..."

# Check Product Service strategy
PRODUCT_MAX_SURGE=$(kubectl get deployment product-service -n $NAMESPACE -o jsonpath='{.spec.strategy.rollingUpdate.maxSurge}')
PRODUCT_MAX_UNAVAILABLE=$(kubectl get deployment product-service -n $NAMESPACE -o jsonpath='{.spec.strategy.rollingUpdate.maxUnavailable}')

echo "Product Service:"
echo "   maxSurge: $PRODUCT_MAX_SURGE (should be 1)"
echo "   maxUnavailable: $PRODUCT_MAX_UNAVAILABLE (should be 0 for zero downtime)"

if [ "$PRODUCT_MAX_SURGE" = "1" ] && [ "$PRODUCT_MAX_UNAVAILABLE" = "0" ]; then
    echo "✅ Product Service rolling update strategy correct"
else
    echo "❌ Product Service rolling update strategy incorrect"
    FAILED=1
fi

# Check Order Service strategy
ORDER_MAX_SURGE=$(kubectl get deployment order-service -n $NAMESPACE -o jsonpath='{.spec.strategy.rollingUpdate.maxSurge}')
ORDER_MAX_UNAVAILABLE=$(kubectl get deployment order-service -n $NAMESPACE -o jsonpath='{.spec.strategy.rollingUpdate.maxUnavailable}')

echo ""
echo "Order Service:"
echo "   maxSurge: $ORDER_MAX_SURGE (should be 1)"
echo "   maxUnavailable: $ORDER_MAX_UNAVAILABLE (should be 0 for zero downtime)"

if [ "$ORDER_MAX_SURGE" = "1" ] && [ "$ORDER_MAX_UNAVAILABLE" = "0" ]; then
    echo "✅ Order Service rolling update strategy correct"
else
    echo "❌ Order Service rolling update strategy incorrect"
    FAILED=1
fi

# Test 4: Verify Resource Limits (Required for HPA)
echo ""
echo "4️⃣  Verifying Resource Limits (Required for HPA)..."

DEPLOYMENTS=("frontend-v1" "api-gateway-blue" "product-service" "order-service")

for deployment in "${DEPLOYMENTS[@]}"; do
    if kubectl get deployment $deployment -n $NAMESPACE &> /dev/null; then
        CPU_REQUEST=$(kubectl get deployment $deployment -n $NAMESPACE -o jsonpath='{.spec.template.spec.containers[0].resources.requests.cpu}')
        CPU_LIMIT=$(kubectl get deployment $deployment -n $NAMESPACE -o jsonpath='{.spec.template.spec.containers[0].resources.limits.cpu}')
        
        if [ -n "$CPU_REQUEST" ] && [ -n "$CPU_LIMIT" ]; then
            echo "✅ $deployment has CPU requests and limits ($CPU_REQUEST / $CPU_LIMIT)"
        else
            echo "❌ $deployment missing CPU requests/limits"
            FAILED=1
        fi
    fi
done

# Test 5: Verify Labels
echo ""
echo "5️⃣  Verifying Labels..."

# Check if deployments have proper labels
FRONTEND_LABELS=$(kubectl get deployment frontend-v1 -n $NAMESPACE -o jsonpath='{.metadata.labels}' | jq -r 'keys[]' | tr '\n' ' ')
echo "Frontend labels: $FRONTEND_LABELS"

if echo "$FRONTEND_LABELS" | grep -q "app" && echo "$FRONTEND_LABELS" | grep -q "version"; then
    echo "✅ Frontend has required labels (app, version)"
else
    echo "❌ Frontend missing required labels"
    FAILED=1
fi

echo ""
echo "========================================="
if [ $FAILED -eq 0 ]; then
    echo "✅ All Deployment Strategy Tests Passed!"
    echo ""
    echo "Summary:"
    echo "  ✅ Canary deployment properly configured for Frontend"
    echo "  ✅ Blue-Green deployment properly configured for API Gateway"
    echo "  ✅ Rolling updates properly configured for Backend Services"
    echo "  ✅ All services have proper resource limits for HPA"
    exit 0
else
    echo "❌ Some Deployment Strategy Tests Failed"
    exit 1
fi
