import requests
import json
import time

API_KEY = "test_sandbox_key_7x9y2z4a6b8c0d1e3f5g7h9j"
BASE_URL = "http://localhost:8080"

headers = {
    "Content-Type": "application/json",
    "X-API-Key": API_KEY
}

def make_payment(amount, customer_id, description):
    payload = {
        "amount": amount,
        "currency": "USD",
        "customer_id": customer_id,
        "description": description
    }
    
    response = requests.post(
        f"{BASE_URL}/api/v1/initiate-payment",
        headers=headers,
        json=payload
    )
    
    return response.json()

# Example payments
payments = [
    {"amount": 25.99, "customer_id": "USER001", "description": "Monthly subscription"},
    {"amount": 150.00, "customer_id": "USER002", "description": "Product purchase"},
    {"amount": 75.50, "customer_id": "USER003", "description": "Service fee"},
    {"amount": 299.99, "customer_id": "USER004", "description": "Premium package"},
]

print("Processing payments...\n")
for i, payment in enumerate(payments, 1):
    print(f"Payment {i}: {payment['description']} - ${payment['amount']}")
    result = make_payment(**payment)
    
    print(f"  Status: {result.get('payment_status')}")
    print(f"  Transaction ID: {result.get('transaction_id')}")
    print(f"  Reference: {result.get('reference')}")
    print("-" * 50)
    
    time.sleep(1)  # Small delay between payments
