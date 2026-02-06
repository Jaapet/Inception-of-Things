#!/bin/bash

# Setup kubeconfig for K3d
export KUBECONFIG=/tmp/k3d-kubeconfig.yaml

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# GitLab credentials
GITLAB_HOST="localhost/gitlab"
GITLAB_USER="root"
GITLAB_PASSWORD="fpalumbo42"
PROJECT_NAME="iot-app"

echo "=== Setting up GitLab Repository for Argo CD ==="
echo ""

# Step 1: Wait for GitLab to be ready
echo -n "[1/2] Waiting for GitLab to be ready... "
for i in {1..120}; do
    if curl -s "http://$GITLAB_HOST" > /dev/null 2>&1; then
        echo "OK"
        break
    fi
    if [ $i -eq 120 ]; then
        echo "KO"
        echo "Error: GitLab not responding after 120 seconds"
        echo "Hint: GitLab may still be initializing (can take 10-15 minutes)"
        exit 1
    fi
    sleep 1
done

# Step 2: Clone, update, and push to GitLab
echo -n "[2/2] Pushing manifests to GitLab... "
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

# Copy application manifests
mkdir -p confs
cp "$SCRIPT_DIR/bonus/confs/app.yaml" confs/ 2>/dev/null || true

# Commit and push
git config user.email "root@localhost.local"
git config user.name "GitLab Root"
git add .
git commit -m "Add deployment manifests from p3" 2>/dev/null || true
git push -u "http://$GITLAB_USER:$GITLAB_PASSWORD@$GITLAB_HOST/root/$PROJECT_NAME.git" main 2>/dev/null || \
    git push -u "http://$GITLAB_USER:$GITLAB_PASSWORD@$GITLAB_HOST/root/$PROJECT_NAME.git" HEAD 2>/dev/null || true

echo "OK"

echo ""
echo "=== Complete! GitLab repository created ==="
echo ""
echo "GitLab Project: http://$GITLAB_HOST/root/$PROJECT_NAME"
echo "Repository: http://$GITLAB_HOST/root/$PROJECT_NAME.git"
echo ""

# Step 4: Configure Argo CD to sync from GitLab
echo -n "[4/4] Configuring Argo CD to sync from GitLab... "
kubectl apply --validate=false -f "$SCRIPT_DIR/bonus/confs/deploy.yaml" > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "OK"
else
    echo "FAILED"
fi
