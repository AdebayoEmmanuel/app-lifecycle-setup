# Kubernetes E-Commerce Application Lifecycle - Complete Implementation Guide

## Project Overview

This project demonstrates a complete microservices e-commerce application deployment on Kubernetes with advanced deployment strategies, comprehensive health checks, and autoscaling capabilities.

**Team Assignment:** Complete Application Lifecycle  
**Duration:** 3 hours  
**Platform:** Minikube on Ubuntu

## Architecture

### Application Components

1. **Frontend** - nginx serving static content
   - Deployment Strategy: Canary (progressive rollout)
   - Autoscaling: HPA (50-80% CPU target)

2. **API Gateway** - nginx reverse proxy
   - Deployment Strategy: Blue-Green (instant switch)
   - Autoscaling: HPA (custom metric: requests/second)

3. **Product Service** - httpbin for simulation
   - Deployment Strategy: Rolling update
   - Standard Kubernetes rolling update

4. **Order Service** - httpbin for simulation
   - Deployment Strategy: Rolling update
   - Standard Kubernetes rolling update

### Key Features

- **Deployment Strategies**: Canary, Blue-Green, Rolling Updates
- **Configuration Management**: ConfigMaps for service URLs and feature flags, Secrets for API keys
- **Health Checks**: Startup, Readiness, and Liveness probes for all services
- **Autoscaling**: HPA for Frontend and API Gateway
- **Observability**: Ready for metrics collection and monitoring

## Quick Start

```bash
# 1. Start Minikube
./scripts/01-setup-minikube.sh

# 2. Deploy all services
./scripts/02-deploy-all.sh

# 3. Verify deployment
./scripts/03-verify-deployment.sh

# 4. Access services
minikube service frontend -n ecommerce
```

## Project Structure

```
k8s-ecommerce-lifecycle/
├── README.md                           # This file
├── docs/
│   ├── ARCHITECTURE.md                 # Detailed architecture documentation
│   ├── DEPLOYMENT_GUIDE.md            # Step-by-step deployment guide
│   ├── diagrams/
│   │   ├── architecture-overview.md   # System architecture diagram
│   │   ├── canary-deployment.md       # Canary deployment flow
│   │   └── blue-green-deployment.md   # Blue-green deployment flow
├── k8s/
│   ├── namespace.yaml                 # Namespace definition
│   ├── configmaps/
│   │   ├── service-config.yaml        # Service URLs configuration
│   │   └── feature-flags.yaml         # Feature flags
│   ├── secrets/
│   │   └── api-keys.yaml              # API keys (base64 encoded)
│   ├── frontend/
│   │   ├── deployment-v1.yaml         # Frontend v1 deployment
│   │   ├── deployment-v2.yaml         # Frontend v2 for canary
│   │   ├── service.yaml               # Frontend service
│   │   └── hpa.yaml                   # Frontend HPA
│   ├── api-gateway/
│   │   ├── deployment-blue.yaml       # Blue deployment
│   │   ├── deployment-green.yaml      # Green deployment
│   │   ├── service-blue.yaml          # Blue service
│   │   ├── service-green.yaml         # Green service
│   │   ├── service-active.yaml        # Active service (points to blue/green)
│   │   └── hpa.yaml                   # API Gateway HPA
│   ├── product-service/
│   │   ├── deployment.yaml            # Product service deployment
│   │   └── service.yaml               # Product service
│   └── order-service/
│       ├── deployment.yaml            # Order service deployment
│       └── service.yaml               # Order service
├── helm/
│   └── ecommerce-app/
│       ├── Chart.yaml
│       ├── values.yaml
│       ├── templates/
│       │   ├── namespace.yaml
│       │   ├── configmaps.yaml
│       │   ├── secrets.yaml
│       │   ├── frontend/
│       │   ├── api-gateway/
│       │   ├── product-service/
│       │   └── order-service/
├── scripts/
│   ├── 01-setup-minikube.sh          # Minikube setup
│   ├── 02-deploy-all.sh              # Deploy all services
│   ├── 03-verify-deployment.sh       # Verification script
│   ├── 04-canary-rollout.sh          # Canary deployment demo
│   ├── 05-blue-green-switch.sh       # Blue-green switch demo
│   ├── 06-rollback.sh                # Rollback demo
│   ├── 07-test-hpa.sh                # HPA testing
│   └── 08-cleanup.sh                 # Cleanup resources
└── tests/
    ├── health-check-test.sh          # Health check verification
    ├── config-test.sh                # ConfigMap/Secret verification
    └── deployment-strategy-test.sh   # Deployment strategy verification
```

## Prerequisites

### System Requirements
- Ubuntu Linux (20.04 or later)
- 8GB RAM minimum
- 4 CPU cores
- 20GB free disk space

### Required Tools

```bash
# Install Docker
sudo apt-get update
sudo apt-get install -y docker.io
sudo usermod -aG docker $USER

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Install Minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Verify installations
minikube version
kubectl version --client
helm version
```


## Team Members

- [@AdebayoEmmanuel](https://github.com/AdebayoEmmanuel)
- [@Alaswadiyy](https://github.com/alaswadiyy)
- [@Abdulmuhaimin121](https://github.com/Abdulmuhaimin1219)


## License

MIT License
