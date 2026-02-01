# Helm Chart for E-Commerce Application

This Helm chart deploys the complete E-Commerce microservices application with canary and blue-green deployment strategies.

## Installation

### Install from Local Chart

```bash
# Install with default values
helm install ecommerce ./helm/ecommerce-app -n ecommerce --create-namespace

# Install with custom values
helm install ecommerce ./helm/ecommerce-app -n ecommerce --create-namespace -f custom-values.yaml

# Dry run to see what will be deployed
helm install ecommerce ./helm/ecommerce-app -n ecommerce --create-namespace --dry-run --debug
```

### Upgrade

```bash
# Upgrade with new values
helm upgrade ecommerce ./helm/ecommerce-app -n ecommerce

# Upgrade and install if not exists
helm upgrade --install ecommerce ./helm/ecommerce-app -n ecommerce
```

### Uninstall

```bash
helm uninstall ecommerce -n ecommerce
```

## Configuration

The following table lists the configurable parameters and their default values.

### Namespace

| Parameter | Description | Default |
|-----------|-------------|---------|
| `namespace.name` | Kubernetes namespace | `ecommerce` |

### Frontend

| Parameter | Description | Default |
|-----------|-------------|---------|
| `frontend.v1.replicas` | Number of v1 replicas | `3` |
| `frontend.v1.hpa.enabled` | Enable HPA for v1 | `true` |
| `frontend.v1.hpa.minReplicas` | Minimum replicas | `2` |
| `frontend.v1.hpa.maxReplicas` | Maximum replicas | `10` |
| `frontend.v1.hpa.targetCPU` | Target CPU percentage | `50` |
| `frontend.v2.replicas` | Number of v2 replicas (canary) | `0` |

### API Gateway

| Parameter | Description | Default |
|-----------|-------------|---------|
| `apiGateway.blue.replicas` | Blue version replicas | `3` |
| `apiGateway.green.replicas` | Green version replicas | `0` |
| `apiGateway.active.version` | Active version (blue/green) | `blue` |
| `apiGateway.hpa.enabled` | Enable HPA | `true` |
| `apiGateway.hpa.targetCPU` | Target CPU percentage | `60` |

### Backend Services

| Parameter | Description | Default |
|-----------|-------------|---------|
| `productService.replicas` | Product service replicas | `2` |
| `orderService.replicas` | Order service replicas | `2` |

### Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `config.featureFlags.enableCheckout` | Enable checkout feature | `"true"` |
| `config.featureFlags.enableRecommendations` | Enable recommendations | `"false"` |
| `config.featureFlags.logLevel` | Application log level | `"info"` |

## Examples

### Deploy with Custom Replicas

```bash
helm install ecommerce ./helm/ecommerce-app -n ecommerce --create-namespace \
  --set frontend.v1.replicas=5 \
  --set apiGateway.blue.replicas=4
```

### Enable Canary Deployment (10% v2)

```bash
# Set v1 to 3 replicas and v2 to 1 replica for ~25% traffic to v2
helm upgrade ecommerce ./helm/ecommerce-app -n ecommerce \
  --set frontend.v1.replicas=3 \
  --set frontend.v2.replicas=1
```

### Switch to Green Deployment

```bash
# Deploy green and switch active version
helm upgrade ecommerce ./helm/ecommerce-app -n ecommerce \
  --set apiGateway.green.replicas=3 \
  --set apiGateway.active.version=green
```

### Disable a Feature Flag

```bash
helm upgrade ecommerce ./helm/ecommerce-app -n ecommerce \
  --set config.featureFlags.enableCheckout="false"
```

## Deployment Strategies

### Canary Deployment (Frontend)

1. **Deploy v2 with minimal traffic:**
   ```bash
   helm upgrade ecommerce ./helm/ecommerce-app -n ecommerce \
     --set frontend.v1.replicas=3 \
     --set frontend.v2.replicas=1
   ```

2. **Increase to 50% traffic:**
   ```bash
   helm upgrade ecommerce ./helm/ecommerce-app -n ecommerce \
     --set frontend.v1.replicas=2 \
     --set frontend.v2.replicas=2
   ```

3. **Complete migration:**
   ```bash
   helm upgrade ecommerce ./helm/ecommerce-app -n ecommerce \
     --set frontend.v1.replicas=0 \
     --set frontend.v2.replicas=3
   ```

### Blue-Green Deployment (API Gateway)

1. **Deploy green version:**
   ```bash
   helm upgrade ecommerce ./helm/ecommerce-app -n ecommerce \
     --set apiGateway.green.replicas=3
   ```

2. **Switch to green:**
   ```bash
   helm upgrade ecommerce ./helm/ecommerce-app -n ecommerce \
     --set apiGateway.active.version=green
   ```

3. **Decommission blue:**
   ```bash
   helm upgrade ecommerce ./helm/ecommerce-app -n ecommerce \
     --set apiGateway.blue.replicas=0
   ```

## Package Chart

```bash
# Lint the chart
helm lint ./helm/ecommerce-app

# Package the chart
helm package ./helm/ecommerce-app

# This creates: ecommerce-app-1.0.0.tgz
```

## Verify Deployment

```bash
# List all releases
helm list -n ecommerce

# Get release status
helm status ecommerce -n ecommerce

# Get values
helm get values ecommerce -n ecommerce

# Get all manifests
helm get manifest ecommerce -n ecommerce
```

## Troubleshooting

### View Rendered Templates

```bash
helm template ecommerce ./helm/ecommerce-app -n ecommerce
```

### Debug Installation

```bash
helm install ecommerce ./helm/ecommerce-app -n ecommerce --create-namespace --debug
```

### Check Values

```bash
helm show values ./helm/ecommerce-app
```

## Dependencies

This chart has no dependencies.

## Maintainers

- Your Team Name <team@example.com>
