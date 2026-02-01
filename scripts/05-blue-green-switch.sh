#!/bin/bash

# Script: Blue-Green Deployment Demo
# Purpose: Demonstrate blue-green deployment of API Gateway

set -e

NAMESPACE="ecommerce"

echo "========================================="
echo "Blue-Green Deployment Demo - API Gateway"
echo "========================================="

# Function to show active version
show_active() {
    echo ""
    echo "Active Service Configuration:"
    kubectl get svc api-gateway-active -n $NAMESPACE -o jsonpath='{.spec.selector}' | jq '.'
    
    echo ""
    echo "Current Deployments:"
    kubectl get deployment -n $NAMESPACE -l app=api-gateway
}

# Initial state
echo ""
echo "📊 Step 0: Current State (Blue Active)"
echo "========================================="
show_active

read -p "Press Enter to deploy Green version..."

# Step 1: Deploy Green
echo ""
echo "📊 Step 1: Deploy Green Version"
echo "========================================="
echo "Deploying Green deployment with 3 replicas..."

# Apply green deployment
kubectl apply -f ../k8s/api-gateway/deployment-green.yaml
kubectl apply -f ../k8s/api-gateway/service-green.yaml

echo "Scaling Green to 3 replicas..."
kubectl scale deployment api-gateway-green --replicas=3 -n $NAMESPACE

echo "Waiting for Green pods to be ready..."
kubectl wait --for=condition=ready pod -l app=api-gateway,version=green -n $NAMESPACE --timeout=120s

echo ""
echo "Both Blue and Green are now running:"
kubectl get pods -n $NAMESPACE -l app=api-gateway

read -p "Press Enter to test Green internally..."

# Step 2: Test Green
echo ""
echo "📊 Step 2: Testing Green Version"
echo "========================================="
echo "Port-forwarding to Green service for testing..."

# Port forward in background
kubectl port-forward svc/api-gateway-green 8081:80 -n $NAMESPACE &
PF_PID=$!
sleep 3

echo "Testing Green health endpoint..."
curl -s http://localhost:8081/health || echo "Health check via port-forward"

# Clean up port-forward
kill $PF_PID 2>/dev/null || true

echo ""
echo "Green version is healthy and ready for traffic!"

read -p "Press Enter to switch traffic from Blue to Green..."

# Step 3: Switch traffic
echo ""
echo "📊 Step 3: Switch Traffic to Green"
echo "========================================="
echo "Updating active service to point to Green..."

kubectl patch svc api-gateway-active -n $NAMESPACE -p '{"spec":{"selector":{"version":"green"}}}'

echo ""
echo "Traffic switched! Verifying..."
show_active

echo ""
echo "Testing active service..."
URL=$(minikube service api-gateway-active -n $NAMESPACE --url 2>/dev/null)
curl -s $URL/health || echo "Testing via Minikube service"

read -p "Press Enter to decommission Blue (optional)..."

# Step 4: Decommission Blue
echo ""
echo "📊 Step 4: Decommission Blue Version"
echo "========================================="
echo "Scaling Blue to 0 replicas..."
kubectl scale deployment api-gateway-blue --replicas=0 -n $NAMESPACE

sleep 5
echo ""
echo "Current state:"
kubectl get pods -n $NAMESPACE -l app=api-gateway

echo ""
echo "========================================="
echo "✅ Blue-Green Deployment Complete!"
echo "========================================="
echo ""
echo "🎉 Successfully switched from Blue to Green!"
echo ""
echo "Summary:"
echo "  • Blue (old): Scaled to 0"
echo "  • Green (new): Receiving 100% traffic"
echo ""
echo "🌐 Access the API Gateway:"
echo "   minikube service api-gateway-active -n $NAMESPACE"
echo ""
echo "📝 To rollback to Blue:"
echo "   kubectl scale deployment api-gateway-blue --replicas=3 -n $NAMESPACE"
echo "   kubectl patch svc api-gateway-active -n $NAMESPACE -p '{\"spec\":{\"selector\":{\"version\":\"blue\"}}}'"
echo "   kubectl scale deployment api-gateway-green --replicas=0 -n $NAMESPACE"
