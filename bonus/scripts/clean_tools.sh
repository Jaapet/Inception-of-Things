#!/bin/bash

# Uninstall Helm
echo -n "[1/4] Removing Helm... "
if command -v helm &> /dev/null; then
    sudo rm -f $(which helm)
    echo "OK | Removed"
else
    echo "KO | Not found (Skipping)"
fi

# Uninstall K3d
echo -n "[2/4] Removing K3d... "
if command -v k3d &> /dev/null; then
    sudo rm -f $(which k3d)
    echo "OK | Removed"
else
    echo "KO | Not found (Skipping)"
fi

# Uninstall Kubectl
echo -n "[3/4] Removing Kubectl... "
if command -v kubectl &> /dev/null; then
    sudo rm -f $(which kubectl)
    echo "OK | Removed"
else
    echo "KO | Not found (Skipping)"
fi

# Uninstall Docker
echo -n "[4/4] Removing Docker... "
if command -v docker &> /dev/null; then
    sudo systemctl stop docker > /dev/null 2>&1

    sudo apt-get purge -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras > /dev/null 2>&1

    sudo rm -rf /var/lib/docker
    sudo rm -rf /var/lib/containerd
    sudo rm -rf /etc/docker

    sudo groupdel docker > /dev/null 2>&1

    sudo apt-get autoremove -y -qq > /dev/null 2>&1

    echo "OK | Removed"
else
    echo "KO | Not found (Skipping)"
fi
