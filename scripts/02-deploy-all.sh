#!/bin/bash

# Script: Deploy All E-Commerce Services
# Purpose: Deploy complete application stack to Kubernetes

set -e

echo "========================================="
echo "Deploying E-Commerce Application"
echo "========================================="

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
K8S_DIR="$PROJECT_ROOT/k8s"

# Function to wait for pods
wait_for_pods() {
    local label=$1
    local timeout=$2
    echo "⏳ Waiting for pods with label $label to be ready..."
    kubectl wait --for=condition=ready pod -l "$label" -n ecommerce --timeout="${timeout}s" || true
}

# Step 1: Create Namespace
echo ""
echo "1️⃣  Creating namespace..."
kubectl apply -f "$K8S_DIR/namespace.yaml"
sleep 2

# Step 2: Deploy ConfigMaps
echo ""
echo "2️⃣  Deploying ConfigMaps..."
kubectl apply -f "$K8S_DIR/configmaps/"
kubectl get configmaps -n ecommerce

# Step 3: Deploy Secrets
echo ""
echo "3️⃣  Deploying Secrets..."
kubectl apply -f "$K8S_DIR/secrets/"
kubectl get secrets -n ecommerce

# Step 4: Deploy Backend Services
echo ""
echo "4️⃣  Deploying Product Service..."
kubectl apply -f "$K8S_DIR/product-service/"
wait_for_pods "app=product-service" 60

echo ""
echo "5️⃣  Deploying Order Service..."
kubectl apply -f "$K8S_DIR/order-service/"
wait_for_pods "app=order-service" 60

# Step 5: Deploy API Gateway (Blue initially)
echo ""
echo "6️⃣  Deploying API Gateway (Blue version)..."
kubectl apply -f "$K8S_DIR/api-gateway/deployment-blue.yaml"
kubectl apply -f "$K8S_DIR/api-gateway/service-blue.yaml"
kubectl apply -f "$K8S_DIR/api-gateway/service-active.yaml"
kubectl apply -f "$K8S_DIR/api-gateway/hpa.yaml"
wait_for_pods "app=api-gateway,version=blue" 60

# Step 6: Deploy Frontend (v1 initially)
echo ""
echo "7️⃣  Deploying Frontend (v1)..."
kubectl apply -f "$K8S_DIR/frontend/deployment-v1.yaml"
kubectl apply -f "$K8S_DIR/frontend/service.yaml"
kubectl apply -f "$K8S_DIR/frontend/hpa.yaml"
wait_for_pods "app=frontend,version=v1" 60

# Wait a bit for everything to stabilize
echo ""
echo "⏳ Waiting for all services to stabilize..."
sleep 10

# Display deployment status
echo ""
echo "========================================="
echo "Deployment Status"
echo "========================================="
echo ""
echo "📦 Pods:"
kubectl get pods -n ecommerce -o wide
echo ""
echo "🌐 Services:"
kubectl get svc -n ecommerce
echo ""
echo "📊 HPAs:"
kubectl get hpa -n ecommerce
echo ""
echo "📋 ConfigMaps:"
kubectl get cm -n ecommerce
echo ""
echo "🔐 Secrets:"
kubectl get secrets -n ecommerce

echo ""
echo "========================================="
echo "✅ Deployment Complete!"
echo "========================================="
echo ""
echo "🌐 Access the application:"
echo "   Frontend: minikube service frontend -n ecommerce"
echo "   API Gateway: minikube service api-gateway-active -n ecommerce"
echo ""
echo "📊 View metrics:"
echo "   kubectl top pods -n ecommerce"
echo ""
echo "Next steps:"
echo "   - Run ./scripts/03-verify-deployment.sh to verify"
echo "   - Run ./scripts/04-canary-rollout.sh for canary demo"
echo "   - Run ./scripts/05-blue-green-switch.sh for blue-green demo"
