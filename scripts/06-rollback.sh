#!/bin/bash

# Script: Rollback Demo
# Purpose: Demonstrate rollback procedures for both deployment strategies

set -e

NAMESPACE="ecommerce"

echo "========================================="
echo "Rollback Demonstration"
echo "========================================="

echo ""
echo "Select rollback type:"
echo "1) Rollback Canary Deployment (Frontend v2 → v1)"
echo "2) Rollback Blue-Green Deployment (Green → Blue)"
echo "3) Rollback Rolling Update (Product/Order Service)"
echo ""
read -p "Enter choice (1-3): " choice

case $choice in
    1)
        echo ""
        echo "📊 Rolling Back Canary Deployment"
        echo "========================================="
        echo "Current state:"
        kubectl get pods -n $NAMESPACE -l app=frontend
        
        echo ""
        echo "Rolling back from v2 to v1..."
        kubectl scale deployment frontend-v1 --replicas=3 -n $NAMESPACE
        kubectl scale deployment frontend-v2 --replicas=0 -n $NAMESPACE
        
        echo "Waiting for v1 pods to be ready..."
        kubectl wait --for=condition=ready pod -l app=frontend,version=v1 -n $NAMESPACE --timeout=60s
        
        echo ""
        echo "✅ Rollback complete!"
        kubectl get pods -n $NAMESPACE -l app=frontend
        ;;
        
    2)
        echo ""
        echo "📊 Rolling Back Blue-Green Deployment"
        echo "========================================="
        echo "Current active version:"
        kubectl get svc api-gateway-active -n $NAMESPACE -o jsonpath='{.spec.selector}'
        
        echo ""
        echo "Switching back to Blue..."
        kubectl patch svc api-gateway-active -n $NAMESPACE -p '{"spec":{"selector":{"version":"blue"}}}'
        
        echo "Scaling Blue back up..."
        kubectl scale deployment api-gateway-blue --replicas=3 -n $NAMESPACE
        kubectl wait --for=condition=ready pod -l app=api-gateway,version=blue -n $NAMESPACE --timeout=60s
        
        echo "Scaling Green down..."
        kubectl scale deployment api-gateway-green --replicas=0 -n $NAMESPACE
        
        echo ""
        echo "✅ Rollback complete!"
        echo "Active version:"
        kubectl get svc api-gateway-active -n $NAMESPACE -o jsonpath='{.spec.selector}'
        echo ""
        kubectl get pods -n $NAMESPACE -l app=api-gateway
        ;;
        
    3)
        echo ""
        echo "📊 Rolling Back Product Service"
        echo "========================================="
        
        echo "Deployment rollout history:"
        kubectl rollout history deployment/product-service -n $NAMESPACE
        
        echo ""
        read -p "Enter revision number to rollback to (or press Enter for previous): " revision
        
        if [ -z "$revision" ]; then
            echo "Rolling back to previous version..."
            kubectl rollout undo deployment/product-service -n $NAMESPACE
        else
            echo "Rolling back to revision $revision..."
            kubectl rollout undo deployment/product-service --to-revision=$revision -n $NAMESPACE
        fi
        
        echo ""
        echo "Checking rollout status..."
        kubectl rollout status deployment/product-service -n $NAMESPACE
        
        echo ""
        echo "✅ Rollback complete!"
        kubectl get pods -n $NAMESPACE -l app=product-service
        ;;
        
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac

echo ""
echo "========================================="
echo "Rollback completed successfully!"
echo "========================================="
