# Complete Deployment Guide - E-Commerce Microservices

## Table of Contents
1. [Environment Setup](#environment-setup)
2. [Initial Deployment](#initial-deployment)
3. [Canary Deployment Demo](#canary-deployment-demo)
4. [Blue-Green Deployment Demo](#blue-green-deployment-demo)
5. [HPA Testing](#hpa-testing)
6. [Rollback Procedures](#rollback-procedures)
7. [Verification & Testing](#verification--testing)
8. [Troubleshooting](#troubleshooting)

---

## Environment Setup

### Step 1: Install Prerequisites on Ubuntu

```bash
# Update system
sudo apt-get update && sudo apt-get upgrade -y

# Install Docker
sudo apt-get install -y docker.io
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER
newgrp docker

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
kubectl version --client

# Install Minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
minikube version

# Install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
helm version
```

### Step 2: Start Minikube Cluster

```bash
# Start Minikube with sufficient resources
minikube start --memory=6144 --cpus=4 --disk-size=20g --driver=docker

# Enable required addons
minikube addons enable metrics-server
minikube addons enable ingress

# Verify cluster is running
kubectl cluster-info
kubectl get nodes
```

**Expected Output:**
```
NAME       STATUS   ROLES           AGE   VERSION
minikube   Ready    control-plane   1m    v1.28.0
```

---

## Initial Deployment

### Step 3: Create Namespace

```bash
# Navigate to project directory
cd /home/imet/projects/k8s-ecommerce-lifecycle

# Create namespace
kubectl apply -f k8s/namespace.yaml

# Verify namespace
kubectl get namespaces | grep ecommerce
```

### Step 4: Deploy ConfigMaps and Secrets

```bash
# Deploy ConfigMaps
kubectl apply -f k8s/configmaps/

# Deploy Secrets
kubectl apply -f k8s/secrets/

# Verify
kubectl get configmaps -n ecommerce
kubectl get secrets -n ecommerce
```

**Expected Output:**
```
NAME              DATA   AGE
service-config    2      10s
feature-flags     3      10s

NAME       TYPE     DATA   AGE
api-keys   Opaque   3      10s
```

### Step 5: Deploy Backend Services

```bash
# Deploy Product Service
kubectl apply -f k8s/product-service/

# Deploy Order Service
kubectl apply -f k8s/order-service/

# Wait for pods to be ready
kubectl wait --for=condition=ready pod -l app=product-service -n ecommerce --timeout=60s
kubectl wait --for=condition=ready pod -l app=order-service -n ecommerce --timeout=60s

# Verify
kubectl get pods -n ecommerce
```

**Expected Output:**
```
NAME                              READY   STATUS    RESTARTS   AGE
product-service-xxxxxxxxx-xxxxx   1/1     Running   0          30s
product-service-xxxxxxxxx-xxxxx   1/1     Running   0          30s
order-service-xxxxxxxxx-xxxxx     1/1     Running   0          30s
order-service-xxxxxxxxx-xxxxx     1/1     Running   0          30s
```

### Step 6: Deploy API Gateway (Blue)

```bash
# Deploy Blue version initially
kubectl apply -f k8s/api-gateway/deployment-blue.yaml
kubectl apply -f k8s/api-gateway/service-blue.yaml
kubectl apply -f k8s/api-gateway/service-active.yaml
kubectl apply -f k8s/api-gateway/hpa.yaml

# Wait for ready
kubectl wait --for=condition=ready pod -l app=api-gateway,version=blue -n ecommerce --timeout=60s

# Verify
kubectl get pods -n ecommerce -l app=api-gateway
kubectl get svc -n ecommerce -l app=api-gateway
```

### Step 7: Deploy Frontend (v1)

```bash
# Deploy Frontend v1
kubectl apply -f k8s/frontend/deployment-v1.yaml
kubectl apply -f k8s/frontend/service.yaml
kubectl apply -f k8s/frontend/hpa.yaml

# Wait for ready
kubectl wait --for=condition=ready pod -l app=frontend,version=v1 -n ecommerce --timeout=60s

# Verify
kubectl get pods -n ecommerce -l app=frontend
kubectl get hpa -n ecommerce
```

### Step 8: Verify Full Deployment

```bash
# Check all pods
kubectl get pods -n ecommerce

# Check all services
kubectl get svc -n ecommerce

# Check HPA status
kubectl get hpa -n ecommerce

# Access frontend
minikube service frontend -n ecommerce
```

---

## Canary Deployment Demo

### Scenario: Update Frontend from v1 to v2

**Step 1: Current State (100% v1)**

```bash
# Check current deployment
kubectl get deployment frontend-v1 -n ecommerce

# Check traffic distribution
kubectl get pods -n ecommerce -l app=frontend --show-labels
```

**Step 2: Deploy v2 with 10% Traffic**

```bash
# Deploy Frontend v2 with 1 replica (10% of traffic)
kubectl apply -f k8s/frontend/deployment-v2.yaml

# Verify v2 is running
kubectl get pods -n ecommerce -l app=frontend,version=v2

# Traffic is now 90% v1, 10% v2 (based on pod count)
kubectl get pods -n ecommerce -l app=frontend
```

**Expected Output:**
```
NAME                           READY   STATUS    RESTARTS   AGE
frontend-v1-xxxxxxxxx-xxxxx    1/1     Running   0          5m
frontend-v1-xxxxxxxxx-xxxxx    1/1     Running   0          5m
frontend-v1-xxxxxxxxx-xxxxx    1/1     Running   0          5m
frontend-v2-xxxxxxxxx-xxxxx    1/1     Running   0          30s
```

**Step 3: Test v2 and Monitor**

```bash
# Get service URL
minikube service frontend -n ecommerce --url

# Test with curl (run multiple times to see both versions)
for i in {1..20}; do
  curl -s $(minikube service frontend -n ecommerce --url) | grep "Version"
done

# Monitor pod logs
kubectl logs -f deployment/frontend-v2 -n ecommerce
```

**Step 4: Increase to 50% Traffic**

```bash
# Scale v1 down to 2 replicas, v2 up to 2 replicas
kubectl scale deployment frontend-v1 --replicas=2 -n ecommerce
kubectl scale deployment frontend-v2 --replicas=2 -n ecommerce

# Verify
kubectl get pods -n ecommerce -l app=frontend
```

**Step 5: Complete Migration to v2**

```bash
# Scale v2 to full capacity
kubectl scale deployment frontend-v2 --replicas=3 -n ecommerce

# Scale v1 to zero
kubectl scale deployment frontend-v1 --replicas=0 -n ecommerce

# Verify 100% v2
kubectl get pods -n ecommerce -l app=frontend
```

**Expected Output:**
```
NAME                           READY   STATUS    RESTARTS   AGE
frontend-v2-xxxxxxxxx-xxxxx    1/1     Running   0          5m
frontend-v2-xxxxxxxxx-xxxxx    1/1     Running   0          5m
frontend-v2-xxxxxxxxx-xxxxx    1/1     Running   0          5m
```

---

## Blue-Green Deployment Demo

### Scenario: Update API Gateway from Blue to Green

**Step 1: Current State (Blue Active)**

```bash
# Check current active deployment
kubectl get deployment api-gateway-blue -n ecommerce

# Check active service endpoint
kubectl describe svc api-gateway-active -n ecommerce | grep Endpoints
```

**Step 2: Deploy Green Version**

```bash
# Deploy Green deployment
kubectl apply -f k8s/api-gateway/deployment-green.yaml
kubectl apply -f k8s/api-gateway/service-green.yaml

# Wait for Green to be ready
kubectl wait --for=condition=ready pod -l app=api-gateway,version=green -n ecommerce --timeout=60s

# Verify both Blue and Green are running
kubectl get pods -n ecommerce -l app=api-gateway
```

**Expected Output:**
```
NAME                                READY   STATUS    RESTARTS   AGE
api-gateway-blue-xxxxxxxxx-xxxxx    1/1     Running   0          10m
api-gateway-blue-xxxxxxxxx-xxxxx    1/1     Running   0          10m
api-gateway-blue-xxxxxxxxx-xxxxx    1/1     Running   0          10m
api-gateway-green-xxxxxxxxx-xxxxx   1/1     Running   0          30s
api-gateway-green-xxxxxxxxx-xxxxx   1/1     Running   0          30s
api-gateway-green-xxxxxxxxx-xxxxx   1/1     Running   0          30s
```

**Step 3: Test Green Internally**

```bash
# Port-forward to Green service for testing
kubectl port-forward svc/api-gateway-green 8080:80 -n ecommerce &

# Test Green version
curl http://localhost:8080/status/200

# Stop port-forward
killall kubectl
```

**Step 4: Switch Traffic to Green**

```bash
# Edit active service to point to Green
kubectl patch svc api-gateway-active -n ecommerce -p '{"spec":{"selector":{"version":"green"}}}'

# Verify switch
kubectl describe svc api-gateway-active -n ecommerce | grep Selector

# Test through active service
minikube service api-gateway-active -n ecommerce --url
curl $(minikube service api-gateway-active -n ecommerce --url)/status/200
```

**Expected Output:**
```
Selector: app=api-gateway,version=green
```

**Step 5: Decommission Blue (Optional)**

```bash
# Scale down Blue deployment
kubectl scale deployment api-gateway-blue --replicas=0 -n ecommerce

# Verify only Green is running
kubectl get pods -n ecommerce -l app=api-gateway
```

---

## HPA Testing

### Test Frontend HPA (CPU-based)

**Step 1: Generate CPU Load**

```bash
# Get frontend URL
FRONTEND_URL=$(minikube service frontend -n ecommerce --url)

# Generate load (install apache2-utils if needed)
sudo apt-get install -y apache2-utils

# Send 1000 requests with 10 concurrent connections
ab -n 1000 -c 10 $FRONTEND_URL/

# Alternative: Use while loop
while true; do curl -s $FRONTEND_URL > /dev/null; done
```

**Step 2: Monitor HPA**

```bash
# Watch HPA in real-time
kubectl get hpa frontend-hpa -n ecommerce --watch

# Check pod scaling
kubectl get pods -n ecommerce -l app=frontend --watch
```

**Expected Behavior:**
- CPU usage increases above 50%
- HPA scales up pods (max 10)
- After load stops, HPA scales down (after cooldown period)

### Test API Gateway HPA (Custom Metric)

```bash
# Note: Custom metrics require metrics-server and custom metrics adapter
# For this demo, we'll simulate with CPU-based scaling

# Generate load on API Gateway
GATEWAY_URL=$(minikube service api-gateway-active -n ecommerce --url)
ab -n 2000 -c 20 $GATEWAY_URL/status/200

# Monitor HPA
kubectl get hpa api-gateway-hpa -n ecommerce --watch
```

---

## Rollback Procedures

### Rollback Canary Deployment

```bash
# If v2 has issues, rollback to v1
kubectl scale deployment frontend-v1 --replicas=3 -n ecommerce
kubectl scale deployment frontend-v2 --replicas=0 -n ecommerce

# Verify rollback
kubectl get pods -n ecommerce -l app=frontend
```

### Rollback Blue-Green Deployment

```bash
# Switch back to Blue
kubectl patch svc api-gateway-active -n ecommerce -p '{"spec":{"selector":{"version":"blue"}}}'

# Scale Blue back up if needed
kubectl scale deployment api-gateway-blue --replicas=3 -n ecommerce

# Verify
kubectl describe svc api-gateway-active -n ecommerce | grep Selector
```

### Rollback Rolling Update

```bash
# Check rollout history
kubectl rollout history deployment/product-service -n ecommerce

# Rollback to previous version
kubectl rollout undo deployment/product-service -n ecommerce

# Rollback to specific revision
kubectl rollout undo deployment/product-service --to-revision=2 -n ecommerce

# Check rollout status
kubectl rollout status deployment/product-service -n ecommerce
```

---

## Verification & Testing

### Run Automated Tests

```bash
# Run all verification scripts
./scripts/03-verify-deployment.sh

# Test health checks
./tests/health-check-test.sh

# Test configuration
./tests/config-test.sh

# Test deployment strategies
./tests/deployment-strategy-test.sh
```

### Manual Verification Checklist

```bash
# 1. All pods running
kubectl get pods -n ecommerce
# Expected: All pods STATUS=Running, READY=1/1

# 2. All services accessible
kubectl get svc -n ecommerce
# Expected: All services have ClusterIP

# 3. ConfigMaps loaded
kubectl get cm -n ecommerce
kubectl describe cm service-config -n ecommerce

# 4. Secrets loaded
kubectl get secrets -n ecommerce

# 5. HPA configured
kubectl get hpa -n ecommerce
# Expected: Both frontend and api-gateway HPAs present

# 6. Health probes working
kubectl describe pod <pod-name> -n ecommerce | grep -A 5 "Liveness\|Readiness"

# 7. Access services externally
minikube service list -n ecommerce
minikube service frontend -n ecommerce
```

---

## Troubleshooting

### Pod Not Starting

```bash
# Check pod status
kubectl get pods -n ecommerce

# Describe pod for events
kubectl describe pod <pod-name> -n ecommerce

# Check logs
kubectl logs <pod-name> -n ecommerce

# Check previous logs if pod restarted
kubectl logs <pod-name> -n ecommerce --previous
```

### Service Not Accessible

```bash
# Check service endpoints
kubectl get endpoints -n ecommerce

# Verify service selector matches pod labels
kubectl get svc <service-name> -n ecommerce -o yaml | grep selector
kubectl get pods -n ecommerce --show-labels

# Test service from within cluster
kubectl run test-pod --image=busybox -n ecommerce --rm -it -- wget -O- http://<service-name>:80
```

### HPA Not Scaling

```bash
# Check metrics-server
kubectl top nodes
kubectl top pods -n ecommerce

# If metrics not available, restart metrics-server
kubectl rollout restart deployment metrics-server -n kube-system

# Check HPA details
kubectl describe hpa <hpa-name> -n ecommerce

# Verify resource requests are set
kubectl get deployment <deployment-name> -n ecommerce -o yaml | grep -A 3 resources
```

### ConfigMap/Secret Not Loading

```bash
# Verify ConfigMap exists
kubectl get cm -n ecommerce

# Check ConfigMap content
kubectl describe cm <configmap-name> -n ecommerce

# Verify pod is mounting it
kubectl describe pod <pod-name> -n ecommerce | grep -A 10 "Mounts\|Environment"

# Restart pods to reload config
kubectl rollout restart deployment/<deployment-name> -n ecommerce
```

### Canary Deployment Traffic Not Distributing

```bash
# Check pod labels
kubectl get pods -n ecommerce -l app=frontend --show-labels

# Verify service selector (should only match app, not version)
kubectl get svc frontend -n ecommerce -o yaml | grep selector

# Check pod counts
kubectl get deployment -n ecommerce -l app=frontend
```

### Minikube Issues

```bash
# Check Minikube status
minikube status

# View Minikube logs
minikube logs

# Restart Minikube
minikube stop
minikube start

# Delete and recreate cluster
minikube delete
minikube start --memory=6144 --cpus=4 --disk-size=20g
```

---

## Cleanup

```bash
# Delete all resources in namespace
kubectl delete namespace ecommerce

# Stop Minikube
minikube stop

# Delete Minikube cluster
minikube delete
```

---

## Next Steps

1. Package as Helm chart (see Helm documentation)
2. Record demo video showing:
   - Initial deployment
   - Canary rollout
   - Blue-green switch
   - Rollback procedure
   - HPA in action
3. Complete documentation with screenshots
4. Push to Git repository
