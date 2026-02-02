#!/bin/bash

export K3S_KUBECONFIG_MODE="644"

curl -sfL https://get.k3s.io | sh -

while [ ! -f /etc/rancher/k3s/k3s.yaml ]; do
  echo "Waiting for k3s to be installed..."
  sleep 2
done

kubectl get nodes