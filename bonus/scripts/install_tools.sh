#!/bin/bash

# Update system
echo -n "[1/4] Updating system dependencies... "
if sudo apt-get update -qq > /dev/null 2>&1 && sudo apt-get install -y -qq ca-certificates curl gnupg > /dev/null 2>&1; then
    echo "OK"
else
    echo "KO"
    echo "Error: Failed to update system dependencies."
    exit 1
fi

# Install Docker
echo -n "[2/4] Installing Docker... "
if command -v docker &> /dev/null; then
    echo "OK | (Already installed)"
else
    curl -fsSL https://get.docker.com -o get-docker.sh
    if sudo sh get-docker.sh > /dev/null 2>&1; then
        rm get-docker.sh
        sudo usermod -aG docker $USER
        echo "OK | Installed"
        echo "Note: You may need to log out/in for Docker group permissions."
    else
        echo "KO"
        echo "Error: Docker installation failed."
        rm get-docker.sh
        exit 1
    fi
fi

# Install k3d
echo -n "[3/4] Installing k3d... "
if command -v k3d &> /dev/null; then
    echo "OK | (Already installed)"
else
    if curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash > /dev/null 2>&1; then
        echo "OK | Installed"
    else
        echo "KO"
        echo "Error: k3d installation failed."
        exit 1
    fi
fi

# Install kubectl
echo -n "[4/5] Installing kubectl... "
if command -v kubectl &> /dev/null; then
    echo "OK | (Already installed)"
else
    if curl -LO -s "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
    curl -LO -s "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256" && \
    echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check --status && \
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl; then
        rm kubectl kubectl.sha256
        echo "OK | Installed"
    else
        echo "KO"
        echo "Error: kubectl installation or checksum verification failed."
        rm -f kubectl kubectl.sha256
        exit 1
    fi
fi

# Install Helm
echo -n "[5/5] Installing Helm... "
if command -v helm &> /dev/null; then
    echo "OK | (Already installed)"
else
    if curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash > /dev/null 2>&1; then
        echo "OK | Installed"
    else
        echo "KO"
        echo "Error: Helm installation failed."
        exit 1
    fi
fi
