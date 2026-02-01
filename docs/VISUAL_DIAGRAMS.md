# Visual Architecture Diagrams

## 1. Complete System Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                          MINIKUBE CLUSTER                           │
│                                                                     │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │                    Namespace: ecommerce                       │ │
│  │                                                               │ │
│  │  ┌──────────────────────────────────────────────┐            │ │
│  │  │         External Access (NodePort)           │            │ │
│  │  └────────┬─────────────────────┬────────────────┘            │ │
│  │           │                     │                             │ │
│  │           ▼                     ▼                             │ │
│  │  ┌─────────────────┐   ┌─────────────────┐                   │ │
│  │  │   Frontend      │   │  API Gateway    │                   │ │
│  │  │   Service :80   │   │  Active :80     │                   │ │
│  │  └────────┬────────┘   └────────┬────────┘                   │ │
│  │           │                     │                             │ │
│  │  ┌────────┴────────┐   ┌────────┴────────┐                   │ │
│  │  │   Pod Selector  │   │  Version Sel.   │                   │ │
│  │  │   app=frontend  │   │  version=blue   │                   │ │
│  │  └────────┬────────┘   │  or green       │                   │ │
│  │           │            └─────────────────┘                    │ │
│  │           │                     │                             │ │
│  │  ┌────────┴────────┐           │                             │ │
│  │  │  Frontend Pods  │           │                             │ │
│  │  │  ┌───────────┐  │           │                             │ │
│  │  │  │    v1     │  │  ┌────────┴────────┐                    │ │
│  │  │  │  3 pods   │◄─┼──┤  API Gateway    │                    │ │
│  │  │  └───────────┘  │  │  Blue: 3 pods   │                    │ │
│  │  │  ┌───────────┐  │  │  Green: 0 pods  │                    │ │
│  │  │  │    v2     │  │  └────────┬────────┘                    │ │
│  │  │  │  0 pods   │◄─┘           │                             │ │
│  │  │  └───────────┘              │                             │ │
│  │  │ (Canary Deploy)│            │ (Blue-Green)                │ │
│  │  └─────────────────┘           │                             │ │
│  │                                 │                             │ │
│  │         HPA: 2-10 replicas      │    HPA: 2-8 replicas        │ │
│  │         Target: 50% CPU         │    Target: 60% CPU          │ │
│  │                                 │                             │ │
│  │                        ┌────────┴────────┐                    │ │
│  │                        │  Nginx Config   │                    │ │
│  │                        │  (Routes to:)   │                    │ │
│  │                        └─────┬──────┬────┘                    │ │
│  │                              │      │                         │ │
│  │                 ┌────────────┘      └────────────┐            │ │
│  │                 ▼                                ▼            │ │
│  │        ┌─────────────────┐             ┌─────────────────┐   │ │
│  │        │ Product Service │             │  Order Service  │   │ │
│  │        │   ClusterIP     │             │   ClusterIP     │   │ │
│  │        │     :8080       │             │     :8080       │   │ │
│  │        └────────┬────────┘             └────────┬────────┘   │ │
│  │                 │                               │            │ │
│  │        ┌────────┴────────┐             ┌────────┴────────┐   │ │
│  │        │   httpbin pods  │             │   httpbin pods  │   │ │
│  │        │    2 replicas   │             │    2 replicas   │   │ │
│  │        └─────────────────┘             └─────────────────┘   │ │
│  │         (Rolling Update)                (Rolling Update)     │ │
│  │                                                               │ │
│  │  ──────────────────────────────────────────────────────────  │ │
│  │                    Configuration Layer                       │ │
│  │  ──────────────────────────────────────────────────────────  │ │
│  │                                                               │ │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌────────────┐   │ │
│  │  │  ConfigMaps     │  │   Secrets       │  │    HPAs    │   │ │
│  │  │                 │  │                 │  │            │   │ │
│  │  │ • service-config│  │ • api-keys      │  │ • frontend │   │ │
│  │  │ • feature-flags │  │   (base64)      │  │ • gateway  │   │ │
│  │  └─────────────────┘  └─────────────────┘  └────────────┘   │ │
│  │                                                               │ │
│  └───────────────────────────────────────────────────────────────┘ │
│                                                                     │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │                   Metrics Server (addon)                      │ │
│  │               Collects CPU/Memory metrics                     │ │
│  └───────────────────────────────────────────────────────────────┘ │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

## 2. Canary Deployment Flow

```
TIME: t0 (Initial State)
┌─────────────────────────────────────────┐
│         Frontend Service                │
│         (app=frontend)                  │
└──────────────┬──────────────────────────┘
               │
        100% Traffic
               │
               ▼
    ┌──────────────────────┐
    │   Frontend-v1        │
    │   ███████████ 3 pods │ ◄── Active
    └──────────────────────┘
    ┌──────────────────────┐
    │   Frontend-v2        │
    │                0 pods│ ◄── Not deployed
    └──────────────────────┘


TIME: t1 (Canary Start - 25% traffic to v2)
┌─────────────────────────────────────────┐
│         Frontend Service                │
│         (app=frontend)                  │
└──────────────┬──────────────────────────┘
               │
      ┌────────┴────────┐
      │                 │
   75% Traffic      25% Traffic
      │                 │
      ▼                 ▼
┌──────────────┐  ┌──────────────┐
│Frontend-v1   │  │Frontend-v2   │
│██████ 3 pods │  │██ 1 pod      │ ◄── Testing
└──────────────┘  └──────────────┘


TIME: t2 (50% traffic to v2)
┌─────────────────────────────────────────┐
│         Frontend Service                │
│         (app=frontend)                  │
└──────────────┬──────────────────────────┘
               │
      ┌────────┴────────┐
      │                 │
   50% Traffic      50% Traffic
      │                 │
      ▼                 ▼
┌──────────────┐  ┌──────────────┐
│Frontend-v1   │  │Frontend-v2   │
│████ 2 pods   │  │████ 2 pods   │ ◄── Validated
└──────────────┘  └──────────────┘


TIME: t3 (Complete - 100% v2)
┌─────────────────────────────────────────┐
│         Frontend Service                │
│         (app=frontend)                  │
└──────────────┬──────────────────────────┘
               │
          100% Traffic
               │
               ▼
    ┌──────────────────────┐
    │   Frontend-v1        │
    │                0 pods│ ◄── Scaled down
    └──────────────────────┘
    ┌──────────────────────┐
    │   Frontend-v2        │
    │   ███████████ 3 pods │ ◄── Active
    └──────────────────────┘
```

## 3. Blue-Green Deployment Flow

```
TIME: t0 (Initial State - Blue Active)
┌─────────────────────────────────────────┐
│     API Gateway Active Service          │
│     selector: version=blue              │
└──────────────┬──────────────────────────┘
               │
          100% Traffic
               │
               ▼
    ┌──────────────────────┐    ┌──────────────────────┐
    │  Gateway-Blue        │    │  Gateway-Green       │
    │  ███████████ 3 pods  │    │                0 pods│
    │  service-blue        │    │  service-green       │
    └──────────────────────┘    └──────────────────────┘
           ACTIVE                      NOT DEPLOYED


TIME: t1 (Green Deployed, Testing)
┌─────────────────────────────────────────┐
│     API Gateway Active Service          │
│     selector: version=blue              │ ◄── Still Blue
└──────────────┬──────────────────────────┘
               │
          100% Traffic
               │
               ▼
    ┌──────────────────────┐    ┌──────────────────────┐
    │  Gateway-Blue        │    │  Gateway-Green       │
    │  ███████████ 3 pods  │    │  ███████████ 3 pods  │
    │  service-blue        │    │  service-green       │
    └──────────────────────┘    └──────────────────────┘
           ACTIVE                      TESTING
                                    (port-forward)


TIME: t2 (Instant Switch to Green)
┌─────────────────────────────────────────┐
│     API Gateway Active Service          │
│     selector: version=green  ◄────────┐ │ ◄── Changed
└──────────────┬──────────────────────┬──┘ │
               │                      │    │
               ✗                 100% Traffic
          No Traffic                  │    │
               │                      ▼    │
    ┌──────────────────────┐    ┌──────────────────────┐
    │  Gateway-Blue        │    │  Gateway-Green       │
    │  ███████████ 3 pods  │    │  ███████████ 3 pods  │
    │  service-blue        │    │  service-green       │
    └──────────────────────┘    └──────────────────────┘
          STANDBY                       ACTIVE


TIME: t3 (Blue Decommissioned)
┌─────────────────────────────────────────┐
│     API Gateway Active Service          │
│     selector: version=green             │
└──────────────┬──────────────────────────┘
               │
          100% Traffic
               │
               ▼
    ┌──────────────────────┐    ┌──────────────────────┐
    │  Gateway-Blue        │    │  Gateway-Green       │
    │                0 pods│    │  ███████████ 3 pods  │
    │  service-blue        │    │  service-green       │
    └──────────────────────┘    └──────────────────────┘
       DECOMMISSIONED                  ACTIVE
```

## 4. HPA Autoscaling Flow

```
SCENARIO: Load Increase

t0: Normal Load (CPU < 50%)
┌────────────────────────────────────┐
│  Frontend Pods                     │
│  ┌──────┐ ┌──────┐ ┌──────┐       │
│  │ Pod1 │ │ Pod2 │ │ Pod3 │       │  CPU: 30%
│  │ 30%  │ │ 30%  │ │ 30%  │       │  Replicas: 3
│  └──────┘ └──────┘ └──────┘       │  Status: Stable
└────────────────────────────────────┘

t1: Load Increases (CPU > 50%)
┌────────────────────────────────────┐
│  Frontend Pods                     │
│  ┌──────┐ ┌──────┐ ┌──────┐       │
│  │ Pod1 │ │ Pod2 │ │ Pod3 │       │  CPU: 65%
│  │ 65%  │ │ 65%  │ │ 65%  │       │  Replicas: 3
│  └──────┘ └──────┘ └──────┘       │  Status: Above Target
└────────────────────────────────────┘
           │
           ▼
    HPA detects high CPU
    Decision: Scale up

t2: HPA Scales Up (30s later)
┌────────────────────────────────────────────────┐
│  Frontend Pods                                 │
│  ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐│
│  │ Pod1 │ │ Pod2 │ │ Pod3 │ │ Pod4 │ │ Pod5 ││  CPU: 40%
│  │ 40%  │ │ 40%  │ │ 40%  │ │ 40%  │ │ 40%  ││  Replicas: 5
│  └──────┘ └──────┘ └──────┘ └──────┘ └──────┘│  Status: Scaled
└────────────────────────────────────────────────┘

t3: Load Decreases (5 min later)
┌────────────────────────────────────────────────┐
│  Frontend Pods                                 │
│  ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐│
│  │ Pod1 │ │ Pod2 │ │ Pod3 │ │ Pod4 │ │ Pod5 ││  CPU: 20%
│  │ 20%  │ │ 20%  │ │ 20%  │ │ 20%  │ │ 20%  ││  Replicas: 5
│  └──────┘ └──────┘ └──────┘ └──────┘ └──────┘│  Status: Stabilizing
└────────────────────────────────────────────────┘
           │
           ▼
    HPA cooldown period (5 min)
    Decision: Scale down

t4: HPA Scales Down
┌────────────────────────────────────┐
│  Frontend Pods                     │
│  ┌──────┐ ┌──────┐ ┌──────┐       │
│  │ Pod1 │ │ Pod2 │ │ Pod3 │       │  CPU: 30%
│  │ 30%  │ │ 30%  │ │ 30%  │       │  Replicas: 3
│  └──────┘ └──────┘ └──────┘       │  Status: Stable
└────────────────────────────────────┘
```

## 5. Health Check Probes Timeline

```
POD STARTUP LIFECYCLE:

0s ────────────────────────────────────────────────────────────►
   │
   ├─ Pod Created
   │
   5s ─ Startup Probe begins (initialDelaySeconds: 5)
   │   │
   │   ├─ Check 1: FAIL
   │   ├─ Check 2: FAIL
   │   ├─ Check 3: SUCCESS ✓
   │
   15s ─ Readiness Probe begins (initialDelaySeconds: 5)
   │    │
   │    ├─ Check 1: SUCCESS ✓
   │    │
   │    ├─► Pod marked READY
   │    │   (receives traffic)
   │    │
   │    └─ Continues every 5s
   │
   15s ─ Liveness Probe begins (initialDelaySeconds: 15)
        │
        ├─ Check 1: SUCCESS ✓
        ├─ Check 2: SUCCESS ✓
        ├─ Check 3: SUCCESS ✓
        │
        └─ Continues every 10s

If Liveness Fails 3 times:
        │
        ├─ Fail 1
        ├─ Fail 2
        ├─ Fail 3
        │
        └─► Container RESTARTED
```

## 6. Configuration Management

```
┌──────────────────────────────────────────────────────────┐
│                    Configuration Sources                  │
├──────────────────────────────────────────────────────────┤
│                                                           │
│  ┌──────────────────┐        ┌─────────────────┐        │
│  │   ConfigMaps     │        │    Secrets      │        │
│  │                  │        │                 │        │
│  │ service-config:  │        │ api-keys:       │        │
│  │ • Product URL    │        │ • Product Key   │        │
│  │ • Order URL      │        │ • Order Key     │        │
│  │ • Gateway URL    │        │ • Payment Key   │        │
│  │ • nginx.conf     │        │ • DB Password   │        │
│  │                  │        │ (base64)        │        │
│  │ feature-flags:   │        └─────────┬───────┘        │
│  │ • Checkout: on   │                  │                │
│  │ • Promo: on      │                  │                │
│  │ • Maint: off     │                  │                │
│  └────────┬─────────┘                  │                │
│           │                            │                │
│           └──────────┬─────────────────┘                │
│                      │                                  │
└──────────────────────┼──────────────────────────────────┘
                       │
            ┌──────────┴──────────┐
            │                     │
            ▼                     ▼
    ┌──────────────┐      ┌──────────────┐
    │ Environment  │      │   Volume     │
    │  Variables   │      │   Mounts     │
    ├──────────────┤      ├──────────────┤
    │ PRODUCT_URL  │      │ nginx.conf   │
    │ ORDER_URL    │      │ /etc/nginx/  │
    │ LOG_LEVEL    │      │              │
    │ API_KEY      │      │              │
    │ (from Secret)│      │              │
    └──────┬───────┘      └──────┬───────┘
           │                     │
           └──────────┬──────────┘
                      │
                      ▼
              ┌───────────────┐
              │  Application  │
              │     Pods      │
              └───────────────┘
```

This visual documentation provides clear understanding of:
- System architecture
- Deployment strategies
- Traffic routing
- Autoscaling behavior
- Health checks
- Configuration flow
