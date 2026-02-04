#!/bin/bash

echo "=========================================="
echo "GitLab Repository Setup"
echo "=========================================="

# Step 1: Wait for GitLab webservice pod to be ready
echo -n "[1/6] Waiting for GitLab to be ready... "
GITLAB_READY=0
for i in {1..120}; do
    PHASE=$(sudo kubectl get pods -n gitlab -l app=webservice --field-selector=status.phase=Running -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    if [ ! -z "$PHASE" ]; then
        GITLAB_READY=1
        echo "OK"
        break
    fi
    if [ $((i % 10)) -eq 0 ]; then
        echo -n "$i "
    else
        echo -n "."
    fi
    sleep 2
done

if [ $GITLAB_READY -eq 0 ]; then
    echo "KO"
    echo "Error: GitLab pods still initializing."
    echo "Check with: sudo kubectl get pods -n gitlab"
    echo "Wait 2-3 minutes and run this script again."
    exit 1
fi

# Step 2: Get GitLab root password
echo -n "[2/6] Getting GitLab root password... "
GITLAB_PASSWORD=$(sudo kubectl get secret gitlab-gitlab-initial-root-password -n gitlab -o jsonpath="{.data.password}" 2>/dev/null | base64 -d)
if [ -z "$GITLAB_PASSWORD" ]; then
    echo "KO"
    echo "Error: Could not retrieve GitLab password"
    exit 1
fi
echo "OK"

# Step 3: Wait for GitLab HTTP endpoint
echo -n "[3/6] Waiting for GitLab HTTP endpoint... "
GITLAB_HTTP_READY=0
for i in {1..60}; do
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:8082/sign_in 2>/dev/null | grep -q "200"; then
        GITLAB_HTTP_READY=1
        echo "OK"
        break
    fi
    echo -n "."
    sleep 1
done

if [ $GITLAB_HTTP_READY -eq 0 ]; then
    echo "KO"
    echo "Error: GitLab HTTP endpoint not responding."
    echo "Check:"
    echo "  sudo kubectl get pods -n gitlab"
    echo "  sudo kubectl logs -n gitlab deployment/gitlab-webservice-default"
    exit 1
fi

# Step 4: Create project via API
echo -n "[4/6] Creating GitLab project 'iot-app'... "

PROJECT_RESPONSE=$(curl -s -X POST http://localhost:8082/api/v4/projects \
  -H "Content-Type: application/json" \
  --user "root:${GITLAB_PASSWORD}" \
  -d '{
    "name": "iot-app",
    "visibility": "public",
    "description": "IoT Application - Kubernetes manifests",
    "issues_enabled": false,
    "merge_requests_enabled": false,
    "wiki_enabled": false
  }' 2>/dev/null || echo "")

if echo "$PROJECT_RESPONSE" | grep -q '"id"'; then
    echo "OK"
else
    echo "KO"
    echo "Error: Could not create project via API"
    echo "Try creating manually at http://localhost:8082"
    exit 1
fi

# Step 5: Clone, add manifests, and push
echo -n "[5/6] Pushing manifests to GitLab... "

WORK_DIR=$(mktemp -d)
trap "rm -rf $WORK_DIR" EXIT

cd "$WORK_DIR"

# Clone the repo with credentials
git clone http://root:"${GITLAB_PASSWORD}"@localhost:8082/root/iot-app.git > /dev/null 2>&1 || {
    echo "KO"
    echo "Error: Could not clone repository"
    exit 1
}

cd iot-app

# Copy manifests from p3/confs
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
if ! cp -r "$SCRIPT_DIR/p3/confs"/* . 2>/dev/null; then
    echo "KO"
    echo "Error: Could not copy manifests from p3/confs"
    exit 1
fi

# Configure git
git config user.email "root@localhost.local"
git config user.name "GitLab Root"

# Commit and push
git add . > /dev/null 2>&1
git commit -m "Initial commit: Kubernetes deployment manifests" 2>/dev/null || true
git push -u origin main 2>/dev/null || git push -u origin master 2>/dev/null

echo "OK"

# Step 6: Apply deploy.yaml
echo -n "[6/6] Applying Argo CD configuration... "
cd "$SCRIPT_DIR/bonus"
if sudo kubectl apply -f ./confs/deploy.yaml > /dev/null 2>&1; then
    echo "OK"
else
    echo "KO"
    echo "Note: Run manually: sudo kubectl apply -f ./confs/deploy.yaml"
fi

# Success
echo ""
echo "=========================================="
echo "Setup Complete!"
echo "=========================================="
echo ""
echo "Access your services:"
echo "  GitLab:      http://localhost:8082 (root / check password below)"
echo "  Argo CD:     http://localhost:8080"
echo "  Application: http://localhost:8888"
echo ""
echo "GitLab root password: $GITLAB_PASSWORD"
echo ""
echo "Verify deployment:"
echo "  sudo kubectl get applications -n argocd"
echo "  sudo kubectl get pods -n dev"
echo ""
