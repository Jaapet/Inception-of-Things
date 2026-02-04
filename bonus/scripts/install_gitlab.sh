#!/bin/bash

# Create gitlab namespace
echo -n "[1/4] Creating gitlab namespace... "
if sudo kubectl create namespace gitlab > /dev/null 2>&1; then
    echo "OK"
else
    echo "OK | (Already exists)"
fi

# Add GitLab Helm repository
echo -n "[2/4] Adding GitLab Helm repository... "
if sudo helm repo add gitlab https://charts.gitlab.io > /dev/null 2>&1 && \
   sudo helm repo update > /dev/null 2>&1; then
    echo "OK"
else
    echo "KO"
    echo "Error: Failed to add GitLab Helm repository."
    exit 1
fi

# Install GitLab using official minimal example
echo -n "[3/4] Installing GitLab... "
if sudo helm upgrade --install gitlab gitlab/gitlab \
  -n gitlab \
  -f https://gitlab.com/gitlab-org/charts/gitlab/raw/master/examples/values-minikube-minimum.yaml \
  --set global.hosts.domain=localhost \
  --set global.hosts.externalIP=127.0.0.1 \
  --set global.hosts.https=false \
  --timeout 600s > /dev/null 2>&1; then
    echo "OK"
else
    echo "KO"
    echo "Error: Failed to install GitLab via Helm."
    exit 1
fi

# Wait for GitLab to be ready
echo -n "[4/4] Waiting for GitLab to initialize... "
if sudo kubectl wait --for=condition=ready --timeout=1200s pod -l app=webservice -n gitlab > /dev/null 2>&1; then
    echo "OK"
else
    echo "KO (Timeout - GitLab may still be initializing)"
fi

echo "------------------------------------------------"
echo "   GitLab URL: http://localhost"
echo ""
echo "   Username: root"
PASS=$(sudo kubectl get secret gitlab-gitlab-initial-root-password -n gitlab -o jsonpath="{.data.password}" 2>/dev/null | base64 -d)
echo "   Password: $PASS"
echo "------------------------------------------------"
