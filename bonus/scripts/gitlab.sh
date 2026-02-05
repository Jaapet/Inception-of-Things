#!/bin/bash

# Setup kubeconfig for K3d
if [ -z "$KUBECONFIG" ]; then
    export KUBECONFIG=/tmp/k3d-kubeconfig.yaml
    docker exec k3d-ndesprezS-server-0 cat /etc/rancher/k3s/k3s.yaml > $KUBECONFIG 2>/dev/null
    kubectl config set-cluster default --insecure-skip-tls-verify=true 2>/dev/null || true
fi

# Install dependencies
echo -n "[1/3] Installing dependencies... "
if ! command -v git &> /dev/null; then
    sudo apt-get update
    sudo apt-get install -y git
fi
echo "OK"

# Add GitLab hostname to /etc/hosts
echo -n "[2/3] Configuring GitLab hostname... "
if ! grep -q "gitlab.k3d.gitlab.com" /etc/hosts; then
    echo "127.0.0.1 gitlab.k3d.gitlab.com" | sudo tee -a /etc/hosts > /dev/null
fi
echo "OK"

# Create gitlab namespace and deploy via Docker
echo -n "[3/3] Deploying GitLab... "
kubectl create namespace gitlab 2>/dev/null || true

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
kubectl apply -f "$SCRIPT_DIR/confs/gitlab.yaml" -n gitlab

echo "OK"

# Wait for pod to be ready
echo -n "[4/4] Waiting for GitLab pod to be ready... "
if kubectl wait --for=condition=Ready pod -l app=gitlab -n gitlab --timeout=300s > /dev/null 2>&1; then
    echo "OK"
else
    echo "KO (still initializing)"
fi

# Port-forward to localhost
echo -n "Setting up port-forward... "
kubectl port-forward -n gitlab svc/gitlab 8082:80 > /dev/null 2>&1 &
sleep 2
echo "OK"

echo ""
echo "GitLab is starting (this may take 2-5 minutes)..."
echo ""
echo "Access GitLab at: http://gitlab.k3d.gitlab.com:8082"
echo ""
echo "Credentials:"
echo "  Username: root"
echo "  Password: GitLabP@ssw0rd2026"
