#!/bin/bash

echo "=== Integration Testing ==="

# Check if Minikube is running
if ! minikube status | grep -q "Running"; then
    echo "Starting Minikube..."
    minikube start
fi

# Build Docker image
echo "Building Docker image..."
docker build -t momo-payment-gateway:test .

# Run container locally
echo "Running container locally..."
docker run -d -p 8081:8080 \
  -e MOMO_API_KEY="test_integration_key" \
  -e MOMO_API_SECRET="test_integration_secret" \
  -e MOMO_MERCHANT_ID="INTEGRATION_TEST" \
  --name momo-test \
  momo-payment-gateway:test

sleep 5

# Test endpoints
echo "Testing endpoints..."
curl -s http://localhost:8081/health | jq .
curl -s http://localhost:8081/api/v1/config | jq .

# Cleanup
docker stop momo-test
docker rm momo-test

echo "=== Integration test complete ==="
