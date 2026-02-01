#!/bin/bash

# Script: Cleanup
# Purpose: Remove all deployed resources

set -e

echo "========================================="
echo "Cleanup E-Commerce Deployment"
echo "========================================="

echo ""
echo "⚠️  This will delete:"
echo "   - Namespace 'ecommerce' and all resources"
echo "   - All pods, services, deployments, etc."
echo ""
read -p "Are you sure? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Cleanup cancelled."
    exit 0
fi

echo ""
echo "🗑️  Deleting namespace and all resources..."
kubectl delete namespace ecommerce --timeout=60s

echo ""
echo "Waiting for namespace to be fully deleted..."
while kubectl get namespace ecommerce &> /dev/null; do
    echo -n "."
    sleep 2
done

echo ""
echo "========================================="
echo "✅ Cleanup Complete!"
echo "========================================="
echo ""
echo "All resources have been removed."
echo ""
echo "To redeploy:"
echo "   ./scripts/02-deploy-all.sh"
echo ""
echo "To stop Minikube:"
echo "   minikube stop"
echo ""
echo "To delete Minikube cluster:"
echo "   minikube delete"
