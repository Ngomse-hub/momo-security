#!/bin/bash
set -e

echo "=== Deploying to Minikube ==="

# Create namespace
kubectl apply -f k8s/manifests/namespace.yaml

# Create test secrets
kubectl create secret generic momo-payment-secrets \
  --namespace=momo-payment \
  --from-literal=momo-api-key="test-local-api-key-$(date +%s)" \
  --from-literal=momo-api-secret="test-local-secret-$(date +%s)" \
  --from-literal=momo-merchant-id="TEST_LOCAL_$(date +%s)" \
  --dry-run=client -o yaml | kubectl apply -f -

# Apply all manifests
kubectl apply -f k8s/manifests/configmap.yaml
kubectl apply -f k8s/manifests/rbac.yaml
kubectl apply -f k8s/manifests/deployment.yaml
kubectl apply -f k8s/manifests/service.yaml

# Wait for deployment
echo "Waiting for pods to be ready..."
kubectl wait --namespace=momo-payment \
  --for=condition=ready pod \
  --selector=app=momo-payment \
  --timeout=90s

# Get pod info
kubectl get pods --namespace=momo-payment

# Create port forward
echo ""
echo "Creating port forward to service..."
echo "API will be available at: http://localhost:8080"
echo "Press Ctrl+C to stop"
echo ""
kubectl port-forward --namespace=momo-payment \
  service/momo-payment-service 8080:80
