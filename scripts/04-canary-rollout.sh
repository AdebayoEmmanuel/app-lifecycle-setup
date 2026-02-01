#!/bin/bash

# Script: Canary Deployment Demo
# Purpose: Demonstrate canary deployment of Frontend v1 -> v2

set -e

NAMESPACE="ecommerce"

echo "========================================="
echo "Canary Deployment Demo - Frontend v1 → v2"
echo "========================================="

# Function to show pod distribution
show_pods() {
    echo ""
    echo "Current Pod Distribution:"
    kubectl get pods -n $NAMESPACE -l app=frontend --no-headers | \
        awk '{print $1}' | \
        sed 's/frontend-v/Version /' | \
        sed 's/-[^-]*-[^-]*$//' | \
        sort | uniq -c
}

# Function to test traffic distribution
test_traffic() {
    local iterations=$1
    echo ""
    echo "Testing traffic distribution ($iterations requests)..."
    
    URL=$(minikube service frontend -n $NAMESPACE --url 2>/dev/null)
    
    v1_count=0
    v2_count=0
    
    for i in $(seq 1 $iterations); do
        response=$(curl -s $URL | grep -o "Version [0-9]\." || echo "Unknown")
        if echo "$response" | grep -q "Version 1"; then
            ((v1_count++))
        elif echo "$response" | grep -q "Version 2"; then
            ((v2_count++))
        fi
    done
    
    total=$((v1_count + v2_count))
    if [ $total -gt 0 ]; then
        v1_percent=$((v1_count * 100 / total))
        v2_percent=$((v2_count * 100 / total))
        echo "  v1: $v1_count requests ($v1_percent%)"
        echo "  v2: $v2_count requests ($v2_percent%)"
    fi
}

# Initial state
echo ""
echo "📊 Step 0: Current State (100% v1)"
echo "========================================="
show_pods
kubectl get deployment -n $NAMESPACE -l app=frontend

read -p "Press Enter to deploy v2 with 10% traffic..."

# Step 1: Deploy v2 with 1 replica (10% traffic)
echo ""
echo "📊 Step 1: Deploy v2 with ~10% traffic"
echo "========================================="
echo "Deploying Frontend v2 with 1 replica..."
kubectl apply -f ../k8s/frontend/deployment-v2.yaml

echo "Scaling v2 to 1 replica..."
kubectl scale deployment frontend-v2 --replicas=1 -n $NAMESPACE

echo "Waiting for v2 to be ready..."
kubectl wait --for=condition=ready pod -l app=frontend,version=v2 -n $NAMESPACE --timeout=60s

show_pods
test_traffic 20

read -p "Press Enter to increase to 50% traffic..."

# Step 2: 50% traffic (2 v1, 2 v2)
echo ""
echo "📊 Step 2: Increase to 50% traffic"
echo "========================================="
echo "Scaling v1 to 2 replicas and v2 to 2 replicas..."
kubectl scale deployment frontend-v1 --replicas=2 -n $NAMESPACE
kubectl scale deployment frontend-v2 --replicas=2 -n $NAMESPACE

echo "Waiting for pods to be ready..."
sleep 10
kubectl wait --for=condition=ready pod -l app=frontend -n $NAMESPACE --timeout=60s

show_pods
test_traffic 20

read -p "Press Enter to complete migration to v2 (100%)..."

# Step 3: 100% v2
echo ""
echo "📊 Step 3: Complete Migration to v2 (100%)"
echo "========================================="
echo "Scaling v2 to 3 replicas and v1 to 0..."
kubectl scale deployment frontend-v2 --replicas=3 -n $NAMESPACE
kubectl scale deployment frontend-v1 --replicas=0 -n $NAMESPACE

echo "Waiting for v2 pods to be ready..."
kubectl wait --for=condition=ready pod -l app=frontend,version=v2 -n $NAMESPACE --timeout=60s

show_pods
test_traffic 10

echo ""
echo "========================================="
echo "✅ Canary Deployment Complete!"
echo "========================================="
echo ""
echo "🎉 Successfully migrated from v1 to v2 using canary deployment"
echo ""
echo "Final state:"
kubectl get pods -n $NAMESPACE -l app=frontend
echo ""
echo "🌐 Access the new version:"
echo "   minikube service frontend -n $NAMESPACE"
echo ""
echo "📝 To rollback to v1:"
echo "   kubectl scale deployment frontend-v1 --replicas=3 -n $NAMESPACE"
echo "   kubectl scale deployment frontend-v2 --replicas=0 -n $NAMESPACE"
