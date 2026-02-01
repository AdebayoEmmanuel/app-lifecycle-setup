#!/bin/bash

# Script: Setup Minikube for E-Commerce Application
# Purpose: Start Minikube cluster with required resources and addons

set -e

echo "========================================="
echo "Starting Minikube Cluster Setup"
echo "========================================="

# Check if Minikube is installed
if ! command -v minikube &> /dev/null; then
    echo "❌ Minikube is not installed. Please install it first."
    exit 1
fi

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is not installed. Please install it first."
    exit 1
fi

echo "✅ Prerequisites check passed"

# Stop existing Minikube cluster if running
if minikube status &> /dev/null; then
    echo "⚠️  Minikube is already running. Stopping it..."
    minikube stop
fi

# Start Minikube with sufficient resources
echo "🚀 Starting Minikube with 6GB RAM and 4 CPUs..."
minikube start \
    --memory=6144 \
    --cpus=4 \
    --disk-size=20g \
    --driver=docker

# Wait for cluster to be ready
echo "⏳ Waiting for cluster to be ready..."
kubectl wait --for=condition=Ready node/minikube --timeout=120s

# Enable required addons
echo "📦 Enabling required addons..."
minikube addons enable metrics-server
minikube addons enable ingress

# Verify metrics-server is running
echo "⏳ Waiting for metrics-server to be ready..."
kubectl wait --for=condition=ready pod -l k8s-app=metrics-server -n kube-system --timeout=120s

# Display cluster info
echo ""
echo "========================================="
echo "Cluster Information"
echo "========================================="
kubectl cluster-info
echo ""
kubectl get nodes
echo ""

# Test metrics server
echo "📊 Testing metrics server..."
sleep 10
kubectl top nodes || echo "⚠️  Metrics not available yet (this is normal, wait a minute)"

echo ""
echo "========================================="
echo "✅ Minikube Setup Complete!"
echo "========================================="
echo "Cluster is ready for deployment."
echo "Next step: Run ./scripts/02-deploy-all.sh"
