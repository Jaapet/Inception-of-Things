#!/bin/bash

# Setup kubeconfig for K3d
export KUBECONFIG=/tmp/k3d-kubeconfig.yaml

# Extract fresh kubeconfig from K3d cluster
docker exec k3d-ndesprezS-server-0 cat /etc/rancher/k3s/k3s.yaml > $KUBECONFIG 2>/dev/null
chmod 644 $KUBECONFIG

# Disable TLS verification for self-signed K3d certs
kubectl config set-cluster default --insecure-skip-tls-verify=true 2>/dev/null || true

# Verify cluster access
kubectl cluster-info > /dev/null 2>&1 || {
    echo "ERROR: Cannot access K3d cluster. Make sure it's running with: k3d cluster list"
    exit 1
}

# Install dependencies
echo -n "[1/3] Installing dependencies... "
if ! command -v git &> /dev/null; then
    sudo apt-get update
    sudo apt-get install -y git
fi
echo "OK"

# Create gitlab namespace and deploy
echo -n "[2/3] Deploying GitLab... "
kubectl create namespace gitlab 2>/dev/null || true

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
kubectl apply --validate=false -f "$SCRIPT_DIR/confs/gitlab.yaml" -n gitlab
kubectl apply --validate=false -f "$SCRIPT_DIR/confs/gitlab-ingress.yaml" -n gitlab

echo "OK"

# Wait for pod to be ready
echo -n "[3/3] Waiting for GitLab pod to be ready... "
if kubectl wait --for=condition=Ready pod -l app=gitlab -n gitlab --timeout=300s > /dev/null 2>&1; then
    echo "OK"
else
    echo "KO (still initializing)"
fi

echo ""
echo "GitLab is starting (this may take 5-15 minutes)..."
echo ""
echo "Access GitLab at: http://localhost/gitlab"
echo ""
echo "Credentials:"
echo "  Username: root"
echo "  Password: fpalumbo42"
echo ""
echo "Monitor initialization with:"
echo "  kubectl logs -n gitlab gitlab -f"
echo ""
echo "Once GitLab is ready, run:"
echo "  bash bonus/scripts/update_repo.sh"
