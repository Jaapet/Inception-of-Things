# Inception-of-Things

## Setup Commands

```bash
# Install Vagrant and VirtualBox
make init

# Clean up: destroy all VMs
make clean

# Full cleanup: destroy VMs and uninstall tools
make fclean
```

---

## Part 1: K3s and Vagrant

---

## Part 2: K3s and Three Simple Applications

### Quick Start

```bash
# Navigate to Part 2
cd p2

# Launch the VM and deploy everything
vagrant up

# Access the applications
curl http://app1.com       # → App 1
curl http://app2.com       # → App 2
curl http://app3.com       # → App 3
curl http://192.168.56.110 # → App 3 (default)
```

### Verify Deployment

```bash
# SSH into the VM
vagrant ssh fpalumboS

# Check all pods
kubectl get pods -A

# Check services
kubectl get svc -A

# Check ingress
kubectl get ingress

# View all resources
kubectl get all -A

# Describe ingress in detail
kubectl describe ingress ingress-apps
