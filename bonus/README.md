# Bonus: GitLab Integration

This bonus adds GitLab to the lab completed in Part 3.

## Requirements

- Part 3 must be fully completed and running (K3d cluster with Argo CD)
- Git installed
- Helm installed

## Quick Start

### 1. Install GitLab

From the bonus directory:

```bash
bash scripts/gitlab.sh
```

This will:
- Install Git and Helm (if needed)
- Configure the `gitlab.k3d.gitlab.com` hostname
- Deploy GitLab via Helm to the cluster
- Wait for initialization

### 2. Access GitLab

After installation, access GitLab (port-forwarding is already set up by gitlab.sh):

- **URL**: http://gitlab.k3d.gitlab.com:8082
- **Username**: root
- **Password**: Check the output from gitlab.sh

### 3. Create Repository and Deploy

```bash
bash scripts/update_repo.sh
```

This will:
- Create a new GitLab project called `buthor`
- Clone it and copy p3 manifests
- Push to GitLab
- Configure Argo CD to watch the repository

## Verify

```bash
# Check GitLab pods
sudo kubectl get pods -n gitlab

# Check Argo CD is synced
sudo kubectl get applications -n argocd

# Check deployed app
sudo kubectl get pods -n dev
```

## Access Services

- **Application**: http://localhost:8888
- **Argo CD**: http://localhost:8080
- **GitLab**: http://gitlab.k3d.gitlab.com:8082

## Update Application

Edit `confs/app-deployment.yaml` in your local GitLab clone:

```bash
# Change image version
sed -i 's/wil42\/playground:v1/wil42\/playground:v2/g' confs/app-deployment.yaml

git add .
git commit -m "Update to v2"
git push
```

Argo CD will automatically detect and deploy the changes.

## Cleanup

```bash
# Stop port-forward
killall kubectl

# Remove GitLab
sudo kubectl delete namespace gitlab
```
