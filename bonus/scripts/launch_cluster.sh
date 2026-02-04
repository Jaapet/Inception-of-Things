#!/bin/bash

# Clean
sudo bash ./scripts/clean_cluster.sh
echo "----- Clean -----"

# Create the Cluster
echo -n "[1/7] Creating Cluster 'fpalumboS'... "
if sudo k3d cluster create fpalumboS --api-port 6443 -p "8888:8888@loadbalancer" -p "8080:30080@server:0" -p "8082:80@loadbalancer" --agents 1 --wait > /dev/null 2>&1; then
    echo "OK"
else
    echo "KO"
    echo "Error: Cluster creation failed (might already exist)."
    exit 1
fi

# Create Namespaces
echo -n "[2/7] Creating namespaces... "
if sudo kubectl create namespace argocd > /dev/null 2>&1 && \
   sudo kubectl create namespace dev > /dev/null 2>&1; then
    echo "OK"
else
    echo "KO"
    echo "Error: Failed to create namespaces."
    exit 1
fi

# Install Argo CD
echo -n "[3/7] Installing Argo CD... "
if sudo kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml --server-side > /dev/null 2>&1; then
    echo "OK"
else
    echo "KO"
    echo "Error: Failed to download/install Argo CD."
    exit 1
fi

# Switch to nodeport
echo -n "[4/7] Wiring Port 8080 -> Argo CD... "
PATCH='{"spec": {"type": "NodePort", "ports": [{"port": 443, "nodePort": 30080, "name": "https"}]}}'
if sudo kubectl patch svc argocd-server -n argocd -p "$PATCH" > /dev/null 2>&1; then
    echo "OK"
else
    echo "KO | Patch failed"
    exit 1
fi

# Wait for Argo CD
echo -n "[5/7] Waiting for Argo CD to init... "
if sudo kubectl wait -n argocd --for=condition=Ready pods --all --timeout=600s > /dev/null 2>&1; then
    echo "OK"
else
    echo "KO"
    echo "Error: Timed out waiting for pods to start."
    exit 1
fi

# Install GitLab
echo -n "[6/7] Installing GitLab... "
if bash ./scripts/install_gitlab.sh > /dev/null 2>&1; then
    echo "OK"
else
    echo "KO"
    echo "Note: GitLab installation may take time. Check with: kubectl get pods -n gitlab"
fi

# Note: deploy.yaml will be applied manually after GitLab repo setup
echo "[7/7] Connecting Argo CD to GitLab... Skipped (apply manually after setup)"

# Get passwords
echo "------------------------------------------------"
echo "   App URL:      http://localhost:8888"
echo "   Argo CD URL:  http://localhost:8080"
echo "   GitLab URL:   http://localhost:8082"
echo ""
echo "   Argo CD:"
echo "   Username: admin"
PASS=$(sudo kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" 2>/dev/null | base64 -d)
echo "   Password: $PASS"
echo ""
echo "   GitLab:"
echo "   Username: root"
GITLAB_PASS=$(sudo kubectl -n gitlab get secret gitlab-gitlab-initial-root-password -o jsonpath='{.data.password}' 2>/dev/null | base64 -d)
echo "   Password: $GITLAB_PASS"
echo "------------------------------------------------"
echo ""
echo "NEXT STEPS:"
echo "1. Create GitLab repository 'iot-app' at http://localhost:8082"
echo "2. Clone it: git clone http://localhost:8082/root/iot-app.git"
echo "3. Copy manifests: cp -r ../p3/confs/* ."
echo "4. Push to GitLab: git add . && git commit -m 'init' && git push"
echo "5. Apply Argo CD config: sudo kubectl apply -f ./confs/deploy.yaml"
echo "------------------------------------------------"