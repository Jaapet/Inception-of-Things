#!/bin/bash

# Setup kubeconfig for K3d
if [ -z "$KUBECONFIG" ]; then
    export KUBECONFIG=/tmp/k3d-kubeconfig.yaml
    docker exec k3d-ndesprezS-server-0 cat /etc/rancher/k3s/k3s.yaml > $KUBECONFIG 2>/dev/null
    kubectl config set-cluster default --insecure-skip-tls-verify=true 2>/dev/null || true
fi

echo -n "[1/3] Deleting GitLab namespace... "
if kubectl delete namespace gitlab > /dev/null 2>&1; then
    echo "OK"
else
    echo "OK | (Not found)"
fi

echo -n "[2/2] Cleaning up residual files... "
rm -f /tmp/gitlab-portforward.log 2>/dev/null || true
echo "OK"

echo "GitLab cleaned!"
