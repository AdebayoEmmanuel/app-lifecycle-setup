#!/bin/bash

# Script: HPA Testing
# Purpose: Test Horizontal Pod Autoscaler with load generation

set -e

NAMESPACE="ecommerce"

echo "========================================="
echo "HPA Testing and Load Generation"
echo "========================================="

# Check if apache2-utils (ab) is installed
if ! command -v ab &> /dev/null; then
    echo "Installing apache2-utils for load testing..."
    sudo apt-get update && sudo apt-get install -y apache2-utils
fi

echo ""
echo "Select service to test:"
echo "1) Frontend HPA (CPU-based autoscaling)"
echo "2) API Gateway HPA (CPU-based autoscaling)"
echo ""
read -p "Enter choice (1-2): " choice

case $choice in
    1)
        SERVICE="frontend"
        HPA="frontend-hpa"
        ;;
    2)
        SERVICE="api-gateway-active"
        HPA="api-gateway-hpa"
        ;;
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac

echo ""
echo "📊 Testing HPA for $SERVICE"
echo "========================================="

# Get service URL
URL=$(minikube service $SERVICE -n $NAMESPACE --url 2>/dev/null)
echo "Service URL: $URL"

# Show initial state
echo ""
echo "Initial state:"
kubectl get hpa $HPA -n $NAMESPACE
kubectl get pods -n $NAMESPACE -l app=${SERVICE%-active}

# Function to monitor HPA
monitor_hpa() {
    echo ""
    echo "Monitoring HPA (press Ctrl+C to stop)..."
    kubectl get hpa $HPA -n $NAMESPACE --watch
}

# Start load generation
echo ""
echo "Starting load generation..."
echo "This will send 10000 requests with 50 concurrent connections"
echo ""

read -p "Press Enter to start load test..."

# Run load test in background
echo "Running Apache Bench load test..."
ab -n 10000 -c 50 $URL/ > /tmp/ab-results.txt 2>&1 &
AB_PID=$!

# Monitor HPA in foreground
sleep 2
echo ""
echo "📊 Watch the HPA scale up (this may take 30-60 seconds)..."
kubectl get hpa $HPA -n $NAMESPACE --watch &
WATCH_PID=$!

# Wait for load test to complete
wait $AB_PID

echo ""
echo "Load test complete!"

# Kill the watch
kill $WATCH_PID 2>/dev/null || true

# Show results
echo ""
echo "========================================="
echo "Load Test Results"
echo "========================================="
cat /tmp/ab-results.txt | grep -A 20 "Concurrency Level"

echo ""
echo "========================================="
echo "Final HPA State"
echo "========================================="
kubectl get hpa $HPA -n $NAMESPACE

echo ""
echo "Final Pod Count:"
kubectl get pods -n $NAMESPACE -l app=${SERVICE%-active}

echo ""
echo "📊 CPU Usage:"
kubectl top pods -n $NAMESPACE -l app=${SERVICE%-active}

echo ""
echo "========================================="
echo "✅ HPA Test Complete!"
echo "========================================="
echo ""
echo "📝 Observations:"
echo "   - Initial replicas: Check above"
echo "   - CPU target: 50-60%"
echo "   - Pods should scale up when CPU > target"
echo "   - Pods will scale down after 5 min cooldown"
echo ""
echo "To watch scale-down:"
echo "   kubectl get hpa $HPA -n $NAMESPACE --watch"
