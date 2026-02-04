#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}GitLab Repository Setup${NC}"
echo -e "${BLUE}========================================${NC}"

# Step 1: Wait for GitLab webservice pod to be ready
echo -e "\n${BLUE}[1/6] Waiting for GitLab to be ready...${NC}"
GITLAB_READY=0
for i in {1..120}; do
    PHASE=$(sudo kubectl get pods -n gitlab -l app=webservice --field-selector=status.phase=Running -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    if [ ! -z "$PHASE" ]; then
        GITLAB_READY=1
        echo -e "${GREEN}OK${NC}"
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
    echo -e "${RED}KO${NC}"
    echo "GitLab pods still initializing. Check with: sudo kubectl get pods -n gitlab"
    echo "Wait 2-3 minutes and run this script again."
    exit 1
fi

# Step 2: Get GitLab root password
echo -e "${BLUE}[2/6] Getting GitLab root password...${NC}"
GITLAB_PASSWORD=$(sudo kubectl get secret gitlab-gitlab-initial-root-password -n gitlab -o jsonpath="{.data.password}" 2>/dev/null | base64 -d)
if [ -z "$GITLAB_PASSWORD" ]; then
    echo -e "${RED}KO${NC}"
    echo "Error: Could not retrieve GitLab password"
    exit 1
fi
echo -e "${GREEN}OK${NC}"

# Step 3: Wait for GitLab HTTP endpoint
echo -e "${BLUE}[3/6] Waiting for GitLab HTTP endpoint...${NC}"
GITLAB_HTTP_READY=0
for i in {1..60}; do
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:8082/sign_in 2>/dev/null | grep -q "200"; then
        GITLAB_HTTP_READY=1
        echo -e "${GREEN}OK${NC}"
        break
    fi
    echo -n "."
    sleep 1
done

if [ $GITLAB_HTTP_READY -eq 0 ]; then
    echo -e "${RED}KO${NC}"
    echo "GitLab HTTP endpoint not responding. Check:"
    echo "  sudo kubectl get pods -n gitlab"
    echo "  sudo kubectl logs -n gitlab deployment/gitlab-webservice-default"
    exit 1
fi

# Step 4: Get GitLab API token
echo -e "${BLUE}[4/6] Creating GitLab API token...${NC}"

# Try to get or create a personal access token
TOKEN_RESPONSE=$(curl -s -X POST http://localhost:8082/api/v4/personal_access_tokens \
  -H "Content-Type: application/json" \
  --user "root:${GITLAB_PASSWORD}" \
  -d '{
    "name": "setup-token",
    "scopes": ["api", "write_repository"],
    "expires_at": null
  }' 2>/dev/null || echo "{}")

TOKEN=$(echo "$TOKEN_RESPONSE" | grep -o '"token":"[^"]*' | cut -d'"' -f4)

if [ -z "$TOKEN" ]; then
    echo -e "${YELLOW}Warning: Could not create API token${NC}"
    echo "Trying alternative method..."
    TOKEN=""
fi

if [ ! -z "$TOKEN" ]; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${YELLOW}Using basic auth instead${NC}"
fi

# Step 5: Create project via API
echo -e "${BLUE}[5/6] Creating GitLab project 'iot-app'...${NC}"

if [ ! -z "$TOKEN" ]; then
    # Use token auth
    PROJECT_RESPONSE=$(curl -s -X POST http://localhost:8082/api/v4/projects \
      -H "PRIVATE-TOKEN: ${TOKEN}" \
      -H "Content-Type: application/json" \
      -d '{
        "name": "iot-app",
        "visibility": "public",
        "description": "IoT Application - Kubernetes manifests",
        "issues_enabled": false,
        "merge_requests_enabled": false,
        "wiki_enabled": false
      }' 2>/dev/null || echo "")
else
    # Use basic auth
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
fi

if echo "$PROJECT_RESPONSE" | grep -q '"id"'; then
    echo -e "${GREEN}OK${NC}"
else
    # Project might already exist - try to continue
    echo -e "${YELLOW}Warning: Project creation response unclear${NC}"
fi

# Step 6: Clone, add manifests, and push
echo -e "${BLUE}[6/6] Pushing manifests to GitLab...${NC}"

WORK_DIR=$(mktemp -d)
trap "rm -rf $WORK_DIR" EXIT

cd "$WORK_DIR"

# Clone the repo with credentials
git clone http://root:"${GITLAB_PASSWORD}"@localhost:8082/root/iot-app.git > /dev/null 2>&1 || {
    echo -e "${RED}KO${NC}"
    echo "Error: Could not clone repository"
    echo "Check if project 'iot-app' was created at http://localhost:8082"
    exit 1
}

cd iot-app

# Copy manifests from p3/confs
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
if ! cp -r "$SCRIPT_DIR/p3/confs"/* . 2>/dev/null; then
    echo -e "${RED}KO${NC}"
    echo "Error: Could not copy manifests from p3/confs"
    exit 1
fi

# Configure git
git config user.email "root@localhost.local"
git config user.name "GitLab Root"

# Commit and push
git add .
git commit -m "Initial commit: Kubernetes deployment manifests" 2>/dev/null || true
git push -u origin main 2>/dev/null || git push -u origin master 2>/dev/null

echo -e "${GREEN}OK${NC}"

# Apply deploy.yaml
echo -e "\n${BLUE}Applying Argo CD configuration...${NC}"
cd "$SCRIPT_DIR/bonus"
if sudo kubectl apply -f ./confs/deploy.yaml 2>/dev/null; then
    echo -e "${GREEN}✓ Argo CD Application created${NC}"
else
    echo -e "${YELLOW}✗ Could not apply deploy.yaml${NC}"
    echo "Run manually: sudo kubectl apply -f ./confs/deploy.yaml"
fi

# Success
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Setup Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}Access your services:${NC}"
echo "  GitLab:      http://localhost:8082 (root / check output above)"
echo "  Argo CD:     http://localhost:8080"
echo "  Application: http://localhost:8888"
echo ""
echo -e "${BLUE}Verify deployment:${NC}"
echo "  Argo CD Applications: sudo kubectl get applications -n argocd"
echo "  Deployed pods:       sudo kubectl get pods -n dev"
echo ""
