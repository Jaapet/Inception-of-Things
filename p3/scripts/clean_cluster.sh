#!/bin/bash

# Delete the Cluster
echo -n "[1/2] Deleting k3d cluster 'ndesprezS'... "
if sudo k3d cluster delete ndesprezS > /dev/null 2>&1; then
    echo "OK"
else
    echo "KO | (Cluster not found or already deleted)"
fi

# Clean up Kubeconfig
echo -n "[2/2] Cleaning kubeconfig context... "
if sudo kubectl config delete-context k3d-ndesprezS > /dev/null 2>&1; then
    echo "OK"
else
    echo "OK | (Clean)"
fi
