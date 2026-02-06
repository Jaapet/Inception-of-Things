#!/bin/bash

echo "Installing k3s..."
export K3S_KUBECONFIG_MODE="644"
curl -sfL https://get.k3s.io | sh -s - --node-ip=192.168.56.110 --advertise-address=192.168.56.110

if [ $? -ne 0 ]; then
  echo "Failed to install k3s. Exiting."
  exit 1
fi

while [ ! -f /etc/rancher/k3s/k3s.yaml ]; do
  echo "Waiting for k3s to be installed..."
  sleep 2
done
echo "Done"

kubectl apply -f /vagrant/confs/app1/deployment.yml
kubectl apply -f /vagrant/confs/app1/services.yaml
echo "Done"

kubectl apply -f /vagrant/confs/app2/deployment.yml
kubectl apply -f /vagrant/confs/app2/services.yaml
echo "Done"

kubectl apply -f /vagrant/confs/app3/deployment.yml
kubectl apply -f /vagrant/confs/app3/services.yaml
echo "Done"

echo "Deploying ingress..."
kubectl apply -f /vagrant/confs/ingress.yaml
echo "Done"

echo "K3s cluster ready!"
kubectl get nodes