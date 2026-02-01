#!/bin/bash

echo "=== Starting MoMo Payment Gateway Test ==="

# Kill any existing Flask process
pkill -f "python src/app.py" 2>/dev/null

# Set environment
cd ~/Projects/momo-security
source venv/bin/activate
export MOMO_API_KEY="test_key_$(date +%s)"
export MOMO_API_SECRET="test_secret_$(date +%s)"
export MOMO_MERCHANT_ID="TEST_$(date +%s)"

# Start Flask
echo "Starting Flask server..."
python src/app.py > /tmp/flask_test.log 2>&1 &
SERVER_PID=$!
echo "Server PID: $SERVER_PID"

# Wait for server to start
sleep 5

echo ""
echo "=== Testing API Endpoints ==="

# Test 1: Health endpoint
echo "1. Testing /health endpoint:"
curl -s http://localhost:8080/health | python3 -m json.tool

# Test 2: Config endpoint
echo -e "\n2. Testing /api/v1/config endpoint:"
curl -s http://localhost:8080/api/v1/config | python3 -m json.tool

# Test 3: Payment without API key (should fail)
echo -e "\n3. Testing payment without API key (should fail with 401):"
curl -X POST http://localhost:8080/api/v1/initiate-payment \
  -H "Content-Type: application/json" \
  -d '{"amount": 1000, "customer_id": "CUST001"}' \
  -w "\nStatus Code: %{http_code}\n"

# Test 4: Payment with API key (should work)
echo -e "\n4. Testing payment WITH API key (should succeed):"
API_KEY=$(echo $MOMO_API_KEY)
curl -X POST http://localhost:8080/api/v1/initiate-payment \
  -H "Content-Type: application/json" \
  -H "X-API-Key: $API_KEY" \
  -d '{"amount": 5000, "customer_id": "CUST002"}' \
  -w "\nStatus Code: %{http_code}\n"

# Test 5: Validate secrets
echo -e "\n5. Testing secret validation:"
curl -H "X-API-Key: $API_KEY" \
  http://localhost:8080/api/v1/validate-secret \
  -w "\nStatus Code: %{http_code}\n"

# Stop server
echo -e "\n=== Stopping server ==="
kill $SERVER_PID 2>/dev/null
echo "Test complete!"
