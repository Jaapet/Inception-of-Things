#!/bin/bash

# Install dependencies
echo -n "[1/4] Installing dependencies... "
if ! command -v git &> /dev/null; then
    sudo apt-get update
    sudo apt-get install -y git
fi
if ! command -v helm &> /dev/null; then
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi
echo "OK"

# Add GitLab hostname to /etc/hosts
echo -n "[2/4] Configuring GitLab hostname... "
if ! grep -q "gitlab.k3d.gitlab.com" /etc/hosts; then
    echo "127.0.0.1 gitlab.k3d.gitlab.com" | sudo tee -a /etc/hosts
fi
echo "OK"

# Create gitlab namespace and install via Helm
echo -n "[3/4] Installing GitLab via Helm... "
sudo kubectl create namespace gitlab
if sudo helm repo add gitlab https://charts.gitlab.io && \
   sudo helm repo update && \
   sudo helm upgrade --install gitlab gitlab/gitlab \
     -n gitlab \
     -f https://gitlab.com/gitlab-org/charts/gitlab/raw/master/examples/values-minikube-minimum.yaml \
     --set global.hosts.domain=k3d.gitlab.com \
     --set global.hosts.externalIP=127.0.0.1 \
     --set global.hosts.https=false \
     --timeout 600s; then
    echo "OK"
else
    echo "KO"
    echo "Error: Failed to install GitLab"
    exit 1
fi

# Wait for GitLab webservice to be ready
echo -n "[4/4] Waiting for GitLab to initialize... "
if sudo kubectl wait --for=condition=ready --timeout=1200s pod -l app=webservice -n gitlab; then
    echo "OK"
else
    echo "KO (Timeout - GitLab may still be initializing)"
fi

# Get and display credentials
PASS=$(sudo kubectl get secret gitlab-gitlab-initial-root-password -n gitlab -o jsonpath="{.data.password}" 2>/dev/null | base64 -d)

sudo kubectl port-forward -n gitlab svc/gitlab-webservice-default 8082:8080 &
sleep 2

echo "Access GitLab at: http://localhost:8082"
echo ""
echo "Credentials:"
echo "  Username: root"
echo "  Password: $PASS"
