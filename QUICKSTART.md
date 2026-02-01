# Quick Start Guide - E-Commerce Kubernetes Application

## 🚀 Get Started in 5 Minutes

### Prerequisites Check
```bash
# Verify you have everything installed
minikube version
kubectl version --client
helm version
docker --version
```

If any command fails, see [README.md](README.md#prerequisites) for installation instructions.

---

## 📋 Step-by-Step Deployment

### Step 1: Start Minikube (2 minutes)
```bash
cd /home/imet/projects/k8s-ecommerce-lifecycle
./scripts/01-setup-minikube.sh
```

**What this does:** Starts Minikube with 6GB RAM, 4 CPUs, and enables metrics-server and ingress.

---

### Step 2: Deploy Everything (3 minutes)
```bash
./scripts/02-deploy-all.sh
```

**What this deploys:**
- Namespace `ecommerce`
- ConfigMaps (service URLs, feature flags)
- Secrets (API keys)
- Product Service (2 replicas)
- Order Service (2 replicas)
- API Gateway Blue (3 replicas)
- Frontend v1 (3 replicas)
- HPAs for Frontend and API Gateway

---

### Step 3: Verify Deployment (1 minute)
```bash
./scripts/03-verify-deployment.sh
```

**What this checks:**
- All pods running and ready
- All services accessible
- ConfigMaps and Secrets loaded
- Health checks configured
- HPAs active

---

### Step 4: Access the Application
```bash
# Open frontend in browser
minikube service frontend -n ecommerce

# Get all service URLs
minikube service list -n ecommerce
```

---

## 🎬 Demo Scenarios

### Demo 1: Canary Deployment (Frontend v1 → v2)
```bash
./scripts/04-canary-rollout.sh
```

**Interactive demo showing:**
1. Initial state: 100% v1
2. Deploy v2 with 10% traffic
3. Increase to 50% traffic
4. Complete migration to 100% v2

---

### Demo 2: Blue-Green Deployment (API Gateway)
```bash
./scripts/05-blue-green-switch.sh
```

**Interactive demo showing:**
1. Initial state: Blue active
2. Deploy Green version
3. Test Green internally
4. Instant switch from Blue to Green
5. Decommission Blue

---

### Demo 3: Test Autoscaling (HPA)
```bash
./scripts/07-test-hpa.sh
```

**Interactive demo showing:**
1. Initial pod count
2. Generate load with Apache Bench
3. Watch HPA scale up pods
4. Monitor CPU usage
5. Observe scale-down after cooldown

---

### Demo 4: Rollback Procedures
```bash
./scripts/06-rollback.sh
```

**Options:**
1. Rollback canary (v2 → v1)
2. Rollback blue-green (Green → Blue)
3. Rollback rolling update (any service)

---

## ✅ Running Tests

### Test 1: Health Checks
```bash
./tests/health-check-test.sh
```
Verifies all services have startup, readiness, and liveness probes.

### Test 2: Configuration
```bash
./tests/config-test.sh
```
Verifies ConfigMaps and Secrets are properly loaded.

### Test 3: Deployment Strategies
```bash
./tests/deployment-strategy-test.sh
```
Verifies canary, blue-green, and rolling update configurations.

### Run All Tests
```bash
./tests/health-check-test.sh && \
./tests/config-test.sh && \
./tests/deployment-strategy-test.sh
```

---

## 📊 Monitoring Commands

### View Pods
```bash
kubectl get pods -n ecommerce -o wide
```

### View Services
```bash
kubectl get svc -n ecommerce
```

### View HPAs
```bash
kubectl get hpa -n ecommerce --watch
```

### View Resource Usage
```bash
kubectl top nodes
kubectl top pods -n ecommerce
```

### View Logs
```bash
# Specific pod
kubectl logs <pod-name> -n ecommerce

# All frontend pods
kubectl logs -l app=frontend -n ecommerce

# Follow logs
kubectl logs -f deployment/frontend-v1 -n ecommerce
```

### Describe Resources
```bash
kubectl describe pod <pod-name> -n ecommerce
kubectl describe svc frontend -n ecommerce
kubectl describe hpa frontend-hpa -n ecommerce
```

---

## 🔧 Common Tasks

### Scale Manually
```bash
kubectl scale deployment frontend-v1 --replicas=5 -n ecommerce
```

### Update ConfigMap
```bash
# Edit ConfigMap
kubectl edit cm feature-flags -n ecommerce

# Restart pods to reload
kubectl rollout restart deployment/product-service -n ecommerce
```

### Check Rollout History
```bash
kubectl rollout history deployment/product-service -n ecommerce
```

### Port Forward for Testing
```bash
kubectl port-forward svc/product-service 8080:8080 -n ecommerce
# Then: curl http://localhost:8080/status/200
```

### Execute Command in Pod
```bash
kubectl exec -it <pod-name> -n ecommerce -- /bin/sh
```

---

## 🧹 Cleanup

### Delete All Resources
```bash
./scripts/08-cleanup.sh
```

### Stop Minikube
```bash
minikube stop
```

### Delete Minikube Cluster
```bash
minikube delete
```

---

## 📸 Recording Your Demo

### What to Show in Demo Video

1. **Initial Deployment** (2 min)
   - Run setup and deploy scripts
   - Show all pods running
   - Access frontend in browser

2. **Canary Deployment** (3 min)
   - Show initial state (v1)
   - Deploy v2
   - Show traffic distribution
   - Complete migration

3. **Blue-Green Deployment** (3 min)
   - Show Blue active
   - Deploy Green
   - Switch traffic
   - Show instant switch

4. **Autoscaling** (2 min)
   - Show initial pods
   - Generate load
   - Watch HPA scale up
   - Show increased pods

5. **Rollback** (2 min)
   - Choose a rollback scenario
   - Show rollback execution
   - Verify rollback success

6. **Testing** (2 min)
   - Run verification script
   - Show all tests passing

**Total Demo Time: ~15 minutes**

---

## 🐛 Troubleshooting

### Pods Not Starting
```bash
kubectl describe pod <pod-name> -n ecommerce
kubectl logs <pod-name> -n ecommerce
```

### Service Not Accessible
```bash
kubectl get endpoints -n ecommerce
kubectl describe svc <service-name> -n ecommerce
```

### HPA Not Scaling
```bash
# Check metrics-server
kubectl top nodes
kubectl top pods -n ecommerce

# Restart metrics-server if needed
kubectl rollout restart deployment metrics-server -n kube-system
```

### Minikube Issues
```bash
minikube status
minikube logs
minikube delete && minikube start --memory=6144 --cpus=4
```

---

## 📚 Next Steps

1. ✅ Complete Helm chart (see [helm/README.md](helm/README.md))
2. ✅ Record demo video
3. ✅ Take screenshots for documentation
4. ✅ Update architecture diagrams
5. ✅ Push to Git repository

---

## 🎯 Assessment Checklist

- [x] Namespace created
- [x] ConfigMaps for service URLs and feature flags
- [x] Secrets for API keys
- [x] All services deployed
- [x] Canary deployment for Frontend
- [x] Blue-green deployment for API Gateway
- [x] Rolling updates for backend services
- [x] Health checks (startup, readiness, liveness)
- [x] HPAs configured
- [x] All tests passing
- [ ] Helm chart created
- [ ] Demo video recorded
- [ ] Documentation complete
- [ ] Repository pushed to Git

---

## 💡 Tips

- Use `kubectl get events -n ecommerce --sort-by='.lastTimestamp'` to see recent events
- Use `minikube dashboard` for visual monitoring
- Keep terminal output for documentation screenshots
- Test rollback procedures before recording demo
- Monitor HPA closely during load testing

---

## 📞 Help

If you encounter issues:

1. Check logs: `kubectl logs <pod-name> -n ecommerce`
2. Check events: `kubectl get events -n ecommerce`
3. Run verification: `./scripts/03-verify-deployment.sh`
4. Check Minikube: `minikube status && minikube logs`
