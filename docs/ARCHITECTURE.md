# E-Commerce Microservices Architecture

## System Architecture Overview

```
                                    ┌─────────────────┐
                                    │   End Users     │
                                    └────────┬────────┘
                                             │
                                             ▼
                              ┌──────────────────────────┐
                              │   Frontend (nginx)       │
                              │  - Static Content        │
                              │  - Canary Deployment     │
                              │  - HPA (CPU 50-80%)      │
                              └──────────┬───────────────┘
                                         │
                                         ▼
                              ┌──────────────────────────┐
                              │  API Gateway (nginx)     │
                              │  - Reverse Proxy         │
                              │  - Blue-Green Deploy     │
                              │  - HPA (req/sec)         │
                              └──────┬───────────┬───────┘
                                     │           │
                    ┌────────────────┴───┐   ┌───┴─────────────────┐
                    ▼                    ▼   ▼                     ▼
         ┌──────────────────┐   ┌──────────────────┐
         │ Product Service  │   │  Order Service   │
         │   (httpbin)      │   │   (httpbin)      │
         │ Rolling Update   │   │ Rolling Update   │
         └──────────────────┘   └──────────────────┘
                    │                    │
                    └────────┬───────────┘
                             ▼
                    ┌─────────────────────┐
                    │   ConfigMaps        │
                    │   - Service URLs    │
                    │   - Feature Flags   │
                    └─────────────────────┘
                             │
                             ▼
                    ┌─────────────────────┐
                    │   Secrets           │
                    │   - API Keys        │
                    └─────────────────────┘
```

## Component Details

### 1. Frontend Service

**Technology**: nginx  
**Purpose**: Serve static HTML/CSS/JS content  
**Deployment Strategy**: Canary Deployment

#### Canary Deployment Flow

```
Initial State (100% v1):
┌──────────────┐
│ Frontend-v1  │ ◄── 100% traffic
│  3 replicas  │
└──────────────┘

Step 1: Deploy v2 (10% traffic):
┌──────────────┐      ┌──────────────┐
│ Frontend-v1  │ ◄─── │ Frontend-v2  │
│  3 replicas  │ 90%  │  1 replica   │ 10%
└──────────────┘      └──────────────┘

Step 2: Increase to 50%:
┌──────────────┐      ┌──────────────┐
│ Frontend-v1  │ ◄─── │ Frontend-v2  │
│  2 replicas  │ 50%  │  2 replicas  │ 50%
└──────────────┘      └──────────────┘

Step 3: Complete (100% v2):
                      ┌──────────────┐
                      │ Frontend-v2  │ ◄── 100% traffic
                      │  3 replicas  │
                      └──────────────┘
```

**Health Checks**:
- Startup Probe: HTTP GET / (initialDelaySeconds: 5, failureThreshold: 30)
- Readiness Probe: HTTP GET / (periodSeconds: 5, failureThreshold: 3)
- Liveness Probe: HTTP GET / (periodSeconds: 10, failureThreshold: 3)

**Autoscaling**:
- Min Replicas: 2
- Max Replicas: 10
- Target CPU: 50-80%

### 2. API Gateway

**Technology**: nginx (reverse proxy)  
**Purpose**: Route requests to backend services  
**Deployment Strategy**: Blue-Green Deployment

#### Blue-Green Deployment Flow

```
Initial State (Blue active):
┌─────────────┐     ┌─────────────┐
│  Blue       │ ◄───│   Active    │
│  3 replicas │     │   Service   │
└─────────────┘     └─────────────┘
┌─────────────┐
│  Green      │
│  0 replicas │
└─────────────┘

Step 1: Deploy Green:
┌─────────────┐     ┌─────────────┐
│  Blue       │ ◄───│   Active    │
│  3 replicas │     │   Service   │
└─────────────┘     └─────────────┘
┌─────────────┐
│  Green      │ (testing)
│  3 replicas │
└─────────────┘

Step 2: Switch Traffic:
┌─────────────┐
│  Blue       │ (standby)
│  3 replicas │
└─────────────┘     
┌─────────────┐     ┌─────────────┐
│  Green      │ ◄───│   Active    │
│  3 replicas │     │   Service   │
└─────────────┘     └─────────────┘

Step 3: Decommission Blue:
┌─────────────┐
│  Blue       │
│  0 replicas │
└─────────────┘     
┌─────────────┐     ┌─────────────┐
│  Green      │ ◄───│   Active    │
│  3 replicas │     │   Service   │
└─────────────┘     └─────────────┘
```

**Health Checks**:
- Startup Probe: HTTP GET /health (initialDelaySeconds: 10, failureThreshold: 30)
- Readiness Probe: HTTP GET /ready (periodSeconds: 5, failureThreshold: 3)
- Liveness Probe: HTTP GET /health (periodSeconds: 10, failureThreshold: 3)

**Autoscaling**:
- Min Replicas: 2
- Max Replicas: 8
- Metric: Custom (requests/second > 100)

### 3. Product Service

**Technology**: httpbin  
**Purpose**: Simulate product catalog API  
**Deployment Strategy**: Rolling Update

**Health Checks**:
- Startup Probe: HTTP GET /status/200 (initialDelaySeconds: 5)
- Readiness Probe: HTTP GET /status/200 (periodSeconds: 5)
- Liveness Probe: HTTP GET /status/200 (periodSeconds: 10)

**Rolling Update Strategy**:
- maxSurge: 1 (1 extra pod during update)
- maxUnavailable: 0 (zero downtime)

### 4. Order Service

**Technology**: httpbin  
**Purpose**: Simulate order processing API  
**Deployment Strategy**: Rolling Update

**Health Checks**:
- Startup Probe: HTTP GET /status/200 (initialDelaySeconds: 5)
- Readiness Probe: HTTP GET /status/200 (periodSeconds: 5)
- Liveness Probe: HTTP GET /status/200 (periodSeconds: 10)

**Rolling Update Strategy**:
- maxSurge: 1
- maxUnavailable: 0

## Configuration Management

### ConfigMaps

1. **service-config**: Contains service URLs
```yaml
SERVICE_URLS:
  PRODUCT_SERVICE: "http://product-service:8080"
  ORDER_SERVICE: "http://order-service:8080"
```

2. **feature-flags**: Controls feature rollout
```yaml
FEATURES:
  ENABLE_CHECKOUT: "true"
  ENABLE_RECOMMENDATIONS: "false"
  MAINTENANCE_MODE: "false"
```

### Secrets

1. **api-keys**: Stores sensitive API keys
```yaml
PRODUCT_API_KEY: <base64-encoded>
ORDER_API_KEY: <base64-encoded>
PAYMENT_API_KEY: <base64-encoded>
```

## Network Architecture

```
Namespace: ecommerce
┌────────────────────────────────────────────────────┐
│                                                    │
│  ┌──────────────┐                                 │
│  │  Frontend    │ ClusterIP: 10.96.1.10:80        │
│  └──────────────┘                                 │
│         │                                          │
│         ▼                                          │
│  ┌──────────────┐                                 │
│  │ API Gateway  │ ClusterIP: 10.96.1.20:80        │
│  └──────────────┘                                 │
│         │                                          │
│         ├────────────────┬────────────────┐       │
│         ▼                ▼                ▼       │
│  ┌─────────────┐  ┌─────────────┐               │
│  │  Product    │  │   Order     │               │
│  │  Service    │  │  Service    │               │
│  │ :8080       │  │  :8080      │               │
│  └─────────────┘  └─────────────┘               │
│                                                    │
└────────────────────────────────────────────────────┘
```

## Resource Requirements

| Service | CPU Request | CPU Limit | Memory Request | Memory Limit |
|---------|-------------|-----------|----------------|--------------|
| Frontend | 100m | 200m | 128Mi | 256Mi |
| API Gateway | 100m | 300m | 128Mi | 256Mi |
| Product Service | 50m | 100m | 64Mi | 128Mi |
| Order Service | 50m | 100m | 64Mi | 128Mi |

## Observability

### Metrics Collected
- HTTP request rate
- Response latency
- Error rate
- Pod CPU/Memory usage
- HPA scaling events

### Labels Strategy
All resources use consistent labels:
- `app`: Application name
- `component`: Service component
- `version`: Version identifier
- `environment`: Environment (dev/staging/prod)
- `managed-by`: helm

## Security Considerations

1. **Network Policies**: Restrict pod-to-pod communication
2. **RBAC**: Least privilege access for service accounts
3. **Secrets**: API keys stored as Kubernetes secrets
4. **Image Security**: Use official images, scan for vulnerabilities
5. **Resource Limits**: Prevent resource exhaustion attacks

## Disaster Recovery

### Backup Strategy
- ConfigMaps and Secrets: Version controlled in Git
- Deployment manifests: Stored in Helm charts
- Persistent data: (None for this simulation)

### Rollback Procedures
1. **Canary Rollback**: Scale v2 to 0, scale v1 to desired replicas
2. **Blue-Green Rollback**: Switch active service back to previous color
3. **Rolling Update Rollback**: `kubectl rollout undo deployment/<name>`

## Performance Targets

| Metric | Target |
|--------|--------|
| Response Time (p95) | < 200ms |
| Availability | 99.9% |
| Max Replicas | 10 (Frontend), 8 (Gateway) |
| Scale-up Time | < 30 seconds |
| Zero Downtime | All deployments |
