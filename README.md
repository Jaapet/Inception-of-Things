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
kubectl get ingress -A

# View all resources
kubectl get all -A

# Describe ingress in detail
kubectl describe ingress ingress-apps
```

### Cleanup (Part 2 only)

```bash
cd p2
vagrant destroy -f
```

---

## Part 3: K3d and Argo CD

### Quick Start

```bash
# Install Docker, K3d, kubectl
cd p3
bash scripts/install_tools.sh

# Launch K3d cluster with Argo CD
bash scripts/launch_cluster.sh

# Access the applications
http://localhost:8888  # Application (v1 or v2)
http://localhost:8080  # Argo CD UI (user: admin, password shown in output)
```

### Verify Deployment

```bash
# Check K3d clusters
k3d cluster list

# Check namespaces
kubectl get namespaces

# Check Argo CD
kubectl get all -n argocd

# Check application in dev namespace
kubectl get all -n dev

# Get Argo CD admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

### Update Application Version

```bash
# Edit deployment in GitHub repository to change v1 → v2
# Argo CD will automatically sync the changes
```

### Cleanup (Part 3 only)

```bash
cd p3
bash scripts/clean_cluster.sh
```
