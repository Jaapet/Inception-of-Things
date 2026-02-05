#!/bin/bash

# Get GitLab root password
echo -n "[1/5] Getting GitLab credentials... "
GITLAB_PASSWORD=$(sudo kubectl get secret gitlab-gitlab-initial-root-password -n gitlab -o jsonpath="{.data.password}" 2>/dev/null | base64 -d)
if [ -z "$GITLAB_PASSWORD" ]; then
    echo "KO"
    echo "Error: Could not retrieve GitLab password"
    exit 1
fi
echo "OK"

# Create .netrc for authentication
echo -n "[2/5] Setting up authentication... "
echo "machine gitlab.k3d.gitlab.com" > ~/.netrc
echo "login root" >> ~/.netrc
echo "password $GITLAB_PASSWORD" >> ~/.netrc
chmod 600 ~/.netrc
echo "OK"

# Clone GitLab repo using .netrc credentials
echo -n "[3/5] Cloning GitLab repository... "
WORK_DIR=$(mktemp -d)
trap "rm -rf $WORK_DIR" EXIT

cd "$WORK_DIR"
git clone http://gitlab.k3d.gitlab.com:8082/root/buthor.git || {
    echo "KO"
    echo "Error: Could not clone GitLab repository"
    echo "Verify that the 'buthor' project exists and is PUBLIC"
    exit 1
}

cd buthor

# Copy manifests from p3/confs
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
if ! cp -r "$SCRIPT_DIR/p3/confs"/* . ; then
    echo "KO"
    echo "Error: Could not copy manifests from p3/confs"
    exit 1
fi
echo "OK"

# Commit and push
echo -n "[4/5] Pushing manifests to GitLab... "
git config user.email "root@localhost.local"
git config user.name "GitLab Root"
git add .
git commit -m "Add deployment manifests from p3" || true
git push -u origin main || git push -u origin master
echo "OK"

# Apply deploy.yaml
echo -n "[5/5] Configuring Argo CD... "
cd "$SCRIPT_DIR/bonus"
if sudo kubectl apply -f ./confs/deploy.yaml; then
    echo "OK"
else
    echo "KO"
    echo "Note: Run manually: sudo kubectl apply -f ./confs/deploy.yaml"
fi

echo ""
echo "Complete! GitLab repository updated and Argo CD configured."
echo ""
