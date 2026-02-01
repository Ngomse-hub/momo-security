#!/bin/bash
set -e

echo "=== Setting up MoMo Payment Gateway Locally ==="

# Create Python virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install --upgrade pip
pip install -r requirements.txt

# Start Minikube if not running
if ! minikube status | grep -q "Running"; then
    echo "Starting Minikube..."
    minikube start --driver=docker
fi

# Enable addons
minikube addons enable ingress
minikube addons enable metrics-server

echo "=== Local setup complete ==="
echo ""
echo "To start the application locally:"
echo "1. source venv/bin/activate"
echo "2. python src/app.py"
echo ""
echo "To deploy to Minikube:"
echo "./scripts/deploy-local.sh"
