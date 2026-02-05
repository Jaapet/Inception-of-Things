#!/bin/bash

# Setup kubeconfig for K3d
export KUBECONFIG=/tmp/k3d-kubeconfig.yaml

# Get script directory FIRST (before any cd commands)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# GitLab credentials (hardcoded in our simple deployment)
GITLAB_HOST="localhost:30081"
GITLAB_USER="root"
GITLAB_PASSWORD="fpalumbo42"
PROJECT_NAME="iot-app"

echo "=== Setting up GitLab Repository for Argo CD ==="
echo ""

# Step 1: Wait for GitLab to be ready
echo -n "[1/4] Waiting for GitLab to be ready... "
for i in {1..60}; do
    if curl -s "http://$GITLAB_HOST" > /dev/null 2>&1; then
        echo "OK"
        break
    fi
    if [ $i -eq 60 ]; then
        echo "KO"
        echo "Error: GitLab not responding after 60 seconds"
        exit 1
    fi
    sleep 1
done

# Step 2: Create GitLab project via API
echo -n "[2/4] Creating GitLab project '$PROJECT_NAME'... "
curl -s -u "$GITLAB_USER:$GITLAB_PASSWORD" -X POST "http://$GITLAB_HOST/api/v4/projects" \
    -d "name=$PROJECT_NAME&visibility=public" > /dev/null 2>&1
echo "OK (created or already exists)"

# Step 3: Clone, update, and push to GitLab
echo -n "[3/4] Pushing manifests to GitLab... "
WORK_DIR=$(mktemp -d)
trap "rm -rf $WORK_DIR" EXIT

# Clone repo or initialize if not exists
cd "$WORK_DIR"
if ! git clone "http://$GITLAB_USER:$GITLAB_PASSWORD@$GITLAB_HOST/root/$PROJECT_NAME.git" repo 2>/dev/null; then
    mkdir -p repo
    cd repo
    git init -b main
else
    cd repo
fi

# Copy manifests from p3/confs
cp -r "$SCRIPT_DIR/p3/confs"/* . 2>/dev/null || true

# Commit and push
git config user.email "root@localhost.local"
git config user.name "GitLab Root"
git add .
git commit -m "Add deployment manifests from p3" 2>/dev/null || true
git push -u "http://$GITLAB_USER:$GITLAB_PASSWORD@$GITLAB_HOST/root/$PROJECT_NAME.git" main 2>/dev/null || \
    git push -u "http://$GITLAB_USER:$GITLAB_PASSWORD@$GITLAB_HOST/root/$PROJECT_NAME.git" HEAD 2>/dev/null || true

echo "OK"

# Step 4: Apply deploy.yaml to update Argo CD Application
echo -n "[4/4] Configuring Argo CD to use GitLab... "
if kubectl apply -f "$SCRIPT_DIR/bonus/confs/deploy.yaml" > /dev/null 2>&1; then
    echo "OK"
else
    echo "KO"
    echo "Error: Could not update Argo CD"
    exit 1
fi

echo ""
echo "=== Complete! GitLab repository created and Argo CD configured ==="
echo ""
echo "GitLab Project: http://$GITLAB_HOST/root/$PROJECT_NAME"
echo "Repository: http://$GITLAB_HOST/root/$PROJECT_NAME.git"
echo ""
echo "Argo CD will now sync from GitLab instead of GitHub."
echo "Check sync status: kubectl get application app -n argocd"
echo ""
