#!/bin/bash

# Install k3s
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --write-kubeconfig-mode 644 --node-ip=192.168.56.110 --advertise-address=192.168.56.110" sh -

# Wait for the token (loop until it exists)
while [ ! -f /var/lib/rancher/k3s/server/node-token ]; do
    echo "Waiting for node-token..."
    sleep 2
done

# Share the token
sudo cat /var/lib/rancher/k3s/server/node-token > /vagrant/node-token
