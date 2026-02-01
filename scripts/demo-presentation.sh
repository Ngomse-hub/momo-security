#!/bin/bash

clear
echo "========================================================"
echo "     MoMo Payment Gateway Security - Live Demo"
echo "========================================================"
echo "Presenter: Ngomse-hub (ngomse482@gmail.com)"
echo "Date: $(date)"
echo "========================================================"
echo ""

sleep 2

echo "PHASE 1: Showing the Problem"
echo "-----------------------------"
echo "1. Let's see what happens when secrets are hardcoded..."
echo ""
cat > /tmp/bad_example.py << 'BAD'
# BAD PRACTICE - Hardcoded secrets
MOMO_API_KEY = "sk_test_placeholder"
MOMO_API_SECRET = "momo_secret_1234567890abcdef"

def make_payment():
    # Using hardcoded credentials
    print(f"Using API Key: {MOMO_API_KEY}")
BAD
cat /tmp/bad_example.py
echo ""
echo "❌ This is dangerous! Secrets are visible in git history."
sleep 3

echo ""
echo "2. Let's check if we have any secrets in our code..."
echo ""
grep -r "sk_live\|api_key\|secret" . --include="*.py" --include="*.yaml" --include="*.yml" || echo "✅ No hardcoded secrets found!"
sleep 2

echo ""
echo "PHASE 2: The Solution - GitHub Actions Secrets"
echo "----------------------------------------------"
echo "1. Secrets are stored in GitHub UI (Settings → Secrets)"
echo "   - MOMO_API_KEY"
echo "   - MOMO_API_SECRET" 
echo "   - MOMO_MERCHANT_ID"
echo "   - KUBE_CONFIG"
echo ""
echo "2. They're accessed in workflows like this:"
echo "   \${{ secrets.MOMO_API_KEY }}"
echo ""
echo "3. GitHub automatically masks them in logs"
sleep 3

echo ""
echo "PHASE 3: Kubernetes Secrets Management"
echo "--------------------------------------"
echo "1. Creating a test secret in Kubernetes..."
echo ""
cat > /tmp/test-secret.yaml << 'K8S'
apiVersion: v1
kind: Secret
metadata:
  name: demo-secret
type: Opaque
stringData:
  api-key: "sk_test_1234567890"
  api-secret: "secret_demo_value"
K8S
cat /tmp/test-secret.yaml
sleep 2

echo ""
echo "2. Applying the secret..."
kubectl create namespace demo-secret --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f /tmp/test-secret.yaml --namespace=demo-secret
sleep 2

echo ""
echo "3. Viewing the secret (encoded)..."
kubectl get secret demo-secret --namespace=demo-secret -o yaml | head -10
sleep 2

echo ""
echo "4. Using the secret in a pod..."
cat > /tmp/test-pod.yaml << 'POD'
apiVersion: v1
kind: Pod
metadata:
  name: secret-test-pod
  namespace: demo-secret
spec:
  containers:
  - name: test-container
    image: busybox
    command: ['sh', '-c', 'echo "API Key exists: $API_KEY" && sleep 3600']
    env:
    - name: API_KEY
      valueFrom:
        secretKeyRef:
          name: demo-secret
          key: api-key
POD
kubectl apply -f /tmp/test-pod.yaml --namespace=demo-secret
sleep 3

echo ""
echo "5. Checking the pod logs..."
kubectl logs secret-test-pod --namespace=demo-secret
sleep 2

echo ""
echo "PHASE 4: Complete Pipeline Demo"
echo "-------------------------------"
echo "1. Security scanning with Gitleaks"
echo "2. Automated testing with secrets"
echo "3. Docker image build and push"
echo "4. Kubernetes deployment with secrets injection"
echo "5. Health checks and monitoring"
sleep 3

echo ""
echo "PHASE 5: Best Practices Demonstrated"
echo "------------------------------------"
echo "✅ Secrets are NEVER in source code"
echo "✅ Encrypted at rest (GitHub & Kubernetes)"
echo "✅ Masked in logs"
echo "✅ Principle of least privilege (RBAC)"
echo "✅ Regular rotation capability"
echo "✅ Audit logging"
sleep 3

echo ""
echo "========================================================"
echo "                 DEMO COMPLETE!"
echo "========================================================"
echo ""
echo "Key Takeaways:"
echo "1. Use GitHub Secrets for CI/CD"
echo "2. Use Kubernetes Secrets for runtime"
echo "3. Implement RBAC"
echo "4. Regular security scanning"
echo "5. Monitor and audit access"
echo ""
echo "Repository: https://github.com/Ngomse-hub/momo-payment-security"
echo "========================================================"

# Cleanup
kubectl delete namespace demo-secret --ignore-not-found=true
rm -f /tmp/bad_example.py /tmp/test-secret.yaml /tmp/test-pod.yaml
