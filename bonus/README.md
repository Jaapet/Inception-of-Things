# Bonus: GitLab Integration

This bonus adds GitLab to the lab completed in Part 3. GitLab runs as a Docker container in the K3d cluster and provides a Git repository that Argo CD can connect to.

## Architecture

- **GitLab**: Docker-based Git service running in K3d (namespace: `gitlab`)
- **Argo CD**: Connects to GitLab repository for GitOps sync (namespace: `argocd`)
- **Application**: Deployed via Argo CD watching GitLab repo (namespace: `dev`)

## Requirements

- Part 3 must be fully completed and running (K3d cluster with Argo CD)
- Git installed
- Docker installed (for K3d)

## Quick Start

### 1. Install GitLab

From the bonus directory:

```bash
bash scripts/gitlab.sh
```

This will:
- Install Git (if needed)
- Configure the `gitlab.k3d.gitlab.com` hostname
- Deploy GitLab Docker container to the K3d cluster
- Wait for GitLab pod to be ready
- Set up port-forwarding on port 8082

### 2. Access GitLab

After installation, access GitLab at:

- **URL**: http://gitlab.k3d.gitlab.com:8082
- **Username**: root
- **Password**: Check the output from gitlab.sh (default: `GitLabP@ssw0rd2026`)

**Note**: GitLab may take 5-10 minutes to fully initialize services. If you get an empty response, wait a moment and try again.

### 3. Create Repository and Deploy

```bash
bash scripts/update_repo.sh
```

This will:
- Create a new GitLab project called `buthor`
- Clone it and copy p3 manifests
- Push to GitLab
- Configure Argo CD Application to watch the GitLab repository

## Debugging & Verification

### Check GitLab Status

```bash
# GitLab pods
kubectl get pods -n gitlab

# GitLab logs
kubectl logs -n gitlab gitlab -f

# GitLab service
kubectl get svc -n gitlab
```

### Check Argo CD Integration

```bash
# Argo CD applications (should show "app" synced with GitLab repo)
kubectl get applications -n argocd

# Application details
kubectl describe application app -n argocd

# Deployed application pods
kubectl get pods -n dev
```

### Port-Forward (if needed)

```bash
# GitLab access
kubectl port-forward -n gitlab svc/gitlab 8082:80

# Argo CD access (separate terminal)
kubectl port-forward -n argocd svc/argocd-server 8080:443
```

## Access Services

- **Application**: http://localhost:8888 (deployed by Argo CD)
- **Argo CD Dashboard**: http://localhost:8080 (from P3)
- **GitLab**: http://gitlab.k3d.gitlab.com:8082

## Update Application (GitOps Workflow)

After creating the repository with `update_repo.sh`, you can trigger updates via Git:

```bash
# Clone the repository locally
git clone http://gitlab.k3d.gitlab.com:8082/root/buthor.git
cd buthor

# Edit and push changes
sed -i 's/wil42\/playground:v1/wil42\/playground:v2/g' confs/app-deployment.yaml

git add .
git commit -m "Update to v2"
git push
```

Argo CD will automatically detect and deploy the changes within 2-3 minutes.

## Cleanup

```bash
# Using Makefile
make clean-gitlab

# Or manually
kubectl delete namespace gitlab
pkill -f "kubectl port-forward.*gitlab"
```
