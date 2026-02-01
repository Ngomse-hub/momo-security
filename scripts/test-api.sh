#!/bin/bash

echo "=== Testing MoMo Payment API ==="

# Test health endpoint
echo "1. Testing health endpoint..."
curl -s http://localhost:8080/health | jq .

# Test config endpoint
echo -e "\n2. Testing config endpoint..."
curl -s http://localhost:8080/api/v1/config | jq .

# Test payment initiation (without API key - should fail)
echo -e "\n3. Testing payment without API key (should fail)..."
curl -s -X POST http://localhost:8080/api/v1/initiate-payment \
  -H "Content-Type: application/json" \
  -d '{"amount": 1000, "customer_id": "CUST001"}' | jq .

# Test with API key (get from pod)
echo -e "\n4. Testing with API key..."
POD_NAME=$(kubectl get pods --namespace=momo-payment \
  -l app=momo-payment -o jsonpath='{.items[0].metadata.name}')

API_KEY=$(kubectl exec --namespace=momo-payment $POD_NAME \
  -- printenv MOMO_API_KEY)

curl -s -X POST http://localhost:8080/api/v1/initiate-payment \
  -H "Content-Type: application/json" \
  -H "X-API-Key: $API_KEY" \
  -d '{"amount": 5000, "customer_id": "CUST002"}' | jq .

echo -e "\n=== Tests complete ==="
