# Quick Reference

## Initial Setup

```bash
# 1. Fork repo and clone
git clone https://github.com/<your-username>/vida-interview.git
cd vida-interview

# 2. Run setup script
./setup.sh

# 3. Add GitHub Secrets
# Settings → Secrets → Actions
# - GCP_PROJECT_ID
# - GCP_SA_KEY (contents of vida-sa-key.json)
```

## Common Commands

### Local Development
```bash
make build              # Build Docker image
make run                # Run locally
make test               # Test locally
```

### Terraform
```bash
make staging-plan       # Plan staging changes
make staging-apply      # Deploy to staging
make prod-plan          # Plan production changes
make prod-apply         # Deploy to production
```

### Deployment
```bash
# Deploy to staging
git push origin main

# Deploy to production
git tag v1.0.0
git push origin v1.0.0
```

### Testing
```bash
# Get service URL
cd terraform/environments/staging
terraform output service_url

# Test endpoint
curl $(terraform output -raw service_url) | jq .
```

### Monitoring
```bash
# View logs
gcloud run services logs read vida-interview-staging \
  --region=us-central1 --limit=50

# Check status
gcloud run services list --region=us-central1
```

## File Structure

```
terraform/
├── modules/cloud-run/      # Reusable module
└── environments/
    ├── staging/            # Staging config
    └── production/         # Production config

.github/workflows/
├── deploy.yml              # CI/CD pipeline
└── pr-validation.yml       # PR checks
```

## Environment Variables

| Variable | Staging | Production |
|----------|---------|------------|
| `service_name` | `vida-interview-staging` | `vida-interview-prod` |
| `cpu_limit` | `1000m` | `2000m` |
| `memory_limit` | `512Mi` | `1Gi` |
| `min_instances` | `0` | `1` |
| `max_instances` | `5` | `20` |

## Troubleshooting Quick Checks

```bash
# Is Docker running?
docker ps

# Is gcloud configured?
gcloud config get-value project

# Are APIs enabled?
gcloud services list --enabled | grep run

# Does service account exist?
gcloud iam service-accounts list | grep vida

# Check Terraform state
terraform show

# Check GitHub Actions
# https://github.com/<username>/vida-interview/actions
```

## URLs

- **GitHub Actions**: `https://github.com/<username>/vida-interview/actions`
- **GCP Console**: `https://console.cloud.google.com/run?project=<project-id>`
- **Staging Service**: Check `terraform output service_url`
- **Prod Service**: Check `terraform output service_url`

## Support Resources

- [Deployment Guide](./DEPLOYMENT.md)
- [Testing Guide](./TESTING.md)
- [Terraform Docs](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [Cloud Run Docs](https://cloud.google.com/run/docs)
- [GitHub Actions Docs](https://docs.github.com/en/actions)
