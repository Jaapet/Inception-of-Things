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

### Quick Start

```bash
# Navigate to Part 1
cd p1

# Launch the VMs (server + worker nodes)
vagrant up

# SSH into server node
vagrant ssh <login>S

# SSH into worker node
vagrant ssh <login>SW

# Check cluster status
kubectl get nodes
```

### Verify Deployment

```bash
# SSH into server node
vagrant ssh <login>S

# Check all nodes
kubectl get nodes -o wide

# Check all pods
kubectl get pods -A

# View cluster info
kubectl cluster-info
```

### Cleanup (Part 1 only)

```bash
cd p1
vagrant destroy -f
```

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

---

## Bonus: GitLab Integration

### Quick Start

**Prerequisites:** Part 3 K3d cluster must be running with Argo CD

```bash
# Navigate to bonus directory
cd bonus

# Deploy GitLab to K3d cluster
bash scripts/gitlab.sh

# Setup GitLab repository and configure Argo CD
bash scripts/update_repo.sh
```

### Access Services

```bash
# Application (deployed by Argo CD from GitLab)
http://localhost:8888

# Argo CD UI (GitOps control panel)
http://localhost:8080
Credentials: admin / (password shown during Part 3 setup)

# GitLab (local repository)
http://localhost/gitlab
Credentials: root / fpalumbo42
```

### Setup Flow

1. **Deploy GitLab**:
   ```bash
   bash scripts/gitlab.sh
   ```
   - Creates `gitlab` namespace
   - Deploys GitLab CE latest version
   - Sets up Ingress at `/gitlab`
   - Waits for pod readiness (5-10 minutes)

2. **Configure Argo CD to sync from GitLab**:
   ```bash
   bash scripts/update_repo.sh
   ```
   - Waits for GitLab to be ready
   - Creates `iot-app` project
   - Pushes application manifests (`confs/app.yaml`)
   - Updates Argo CD Application to point to GitLab

### Verify Deployment

```bash
# Check GitLab pod status and services
sudo kubectl get pods -n gitlab
sudo kubectl get svc -n gitlab

# Check Argo CD Application status
kubectl get application app -n argocd

# Check deployed application
kubectl get pods -n dev

# View detailed sync status
kubectl describe application app -n argocd | grep -A 10 "Sync:"

# View GitLab logs
sudo kubectl logs -n gitlab deployment/gitlab -f
```

### Cleanup

```bash
cd bonus
bash scripts/clean_gitlab.sh
```
