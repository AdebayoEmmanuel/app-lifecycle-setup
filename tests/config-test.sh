#!/bin/bash

# Test: Configuration Verification
# Purpose: Verify ConfigMaps and Secrets are properly loaded

set -e

NAMESPACE="ecommerce"
FAILED=0

echo "========================================="
echo "Configuration Verification Test"
echo "========================================="

# Test 1: Verify ConfigMaps exist
echo ""
echo "1️⃣  Verifying ConfigMaps..."
CONFIGMAPS=("service-config" "feature-flags" "frontend-html-v1")

for cm in "${CONFIGMAPS[@]}"; do
    if kubectl get cm $cm -n $NAMESPACE &> /dev/null; then
        echo "✅ ConfigMap '$cm' exists"
        
        # Show content
        echo "   Content:"
        kubectl get cm $cm -n $NAMESPACE -o jsonpath='{.data}' | jq -r 'keys[]' | while read key; do
            echo "      - $key"
        done
    else
        echo "❌ ConfigMap '$cm' not found"
        FAILED=1
    fi
done

# Test 2: Verify Secrets exist
echo ""
echo "2️⃣  Verifying Secrets..."
if kubectl get secret api-keys -n $NAMESPACE &> /dev/null; then
    echo "✅ Secret 'api-keys' exists"
    
    # Show keys (not values)
    echo "   Keys:"
    kubectl get secret api-keys -n $NAMESPACE -o jsonpath='{.data}' | jq -r 'keys[]' | while read key; do
        echo "      - $key"
    done
else
    echo "❌ Secret 'api-keys' not found"
    FAILED=1
fi

# Test 3: Verify environment variables in pods
echo ""
echo "3️⃣  Verifying Environment Variables in Pods..."

# Check Product Service
PRODUCT_POD=$(kubectl get pod -n $NAMESPACE -l app=product-service -o jsonpath='{.items[0].metadata.name}')
if [ -n "$PRODUCT_POD" ]; then
    echo "Checking $PRODUCT_POD..."
    
    # Check if env vars are loaded
    if kubectl exec -n $NAMESPACE $PRODUCT_POD -- env | grep -q "PRODUCT_API_KEY"; then
        echo "✅ PRODUCT_API_KEY loaded"
    else
        echo "❌ PRODUCT_API_KEY not loaded"
        FAILED=1
    fi
    
    if kubectl exec -n $NAMESPACE $PRODUCT_POD -- env | grep -q "LOG_LEVEL"; then
        echo "✅ LOG_LEVEL loaded"
    else
        echo "❌ LOG_LEVEL not loaded"
        FAILED=1
    fi
fi

# Test 4: Verify ConfigMap volume mounts
echo ""
echo "4️⃣  Verifying Volume Mounts..."

# Check API Gateway nginx config
API_POD=$(kubectl get pod -n $NAMESPACE -l app=api-gateway -o jsonpath='{.items[0].metadata.name}')
if [ -n "$API_POD" ]; then
    echo "Checking nginx config in $API_POD..."
    
    if kubectl exec -n $NAMESPACE $API_POD -- ls /etc/nginx/conf.d/default.conf &> /dev/null; then
        echo "✅ nginx config mounted correctly"
    else
        echo "❌ nginx config not mounted"
        FAILED=1
    fi
fi

# Test 5: Verify feature flags values
echo ""
echo "5️⃣  Verifying Feature Flags..."
kubectl get cm feature-flags -n $NAMESPACE -o jsonpath='{.data}' | jq '.'

CHECKOUT=$(kubectl get cm feature-flags -n $NAMESPACE -o jsonpath='{.data.ENABLE_CHECKOUT}')
if [ "$CHECKOUT" = "true" ]; then
    echo "✅ ENABLE_CHECKOUT is enabled"
else
    echo "⚠️  ENABLE_CHECKOUT is disabled"
fi

echo ""
echo "========================================="
if [ $FAILED -eq 0 ]; then
    echo "✅ All Configuration Tests Passed!"
    exit 0
else
    echo "❌ Some Configuration Tests Failed"
    exit 1
fi
