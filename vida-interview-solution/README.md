# Vida Infrastructure/CI Interview - Complete Solution

> **Complete Terraform + GitHub Actions solution for deploying a containerized Flask app to GCP Cloud Run**

## 🎯 What's Included

This solution provides everything needed to deploy the Vida interview application with modern DevOps practices:

- ✅ **Terraform Infrastructure**: Modular, reusable Cloud Run configuration
- ✅ **GitHub Actions CI/CD**: Automated build, test, and deployment pipelines
- ✅ **Environment Separation**: Distinct staging and production configurations
- ✅ **Documentation**: Comprehensive guides for deployment, testing, and troubleshooting
- ✅ **Automation Tools**: Setup scripts and Makefiles for common operations

## 🚀 Quick Start

### 1. Initial Setup (5 minutes)

```bash
# Clone your forked repo
git clone https://github.com/<your-username>/vida-interview.git
cd vida-interview

# Copy these files to your repo
# (All files from vida-interview-solution/)

# Run automated setup
chmod +x setup.sh
./setup.sh
```

### 2. Configure GitHub (2 minutes)

Add these secrets in GitHub (Settings → Secrets → Actions):
- `GCP_PROJECT_ID`: Your GCP project ID
- `GCP_SA_KEY`: Contents of `vida-sa-key.json`

### 3. Deploy (1 command)

```bash
# Deploy to staging
git push origin main

# Deploy to production  
git tag v1.0.0
git push origin v1.0.0
```

## 📁 Project Structure

```
vida-interview/
├── .github/
│   └── workflows/
│       ├── deploy.yml              # Main CI/CD pipeline
│       └── pr-validation.yml       # PR checks
├── terraform/
│   ├── modules/
│   │   └── cloud-run/             # Reusable Cloud Run module
│   │       ├── main.tf
│   │       ├── variables.tf
│   │       └── outputs.tf
│   └── environments/
│       ├── staging/               # Staging environment
│       │   ├── main.tf
│       │   ├── variables.tf
│       │   ├── outputs.tf
│       │   └── terraform.tfvars.example
│       └── production/            # Production environment
│           ├── main.tf
│           ├── variables.tf
│           ├── outputs.tf
│           └── terraform.tfvars.example
├── app.py                         # Flask application (provided)
├── Dockerfile                     # Container definition (provided)
├── requirements.txt               # Python dependencies (provided)
├── Makefile                       # Common operations
├── setup.sh                       # Automated GCP setup
├── .gitignore                     # Prevent credential leaks
├── DEPLOYMENT.md                  # Complete deployment guide
├── TESTING.md                     # Testing & troubleshooting
├── QUICKREF.md                    # Quick reference
└── IMPLEMENTATION.md              # Architecture decisions
```

## 🏗️ Architecture

### Infrastructure: GCP Cloud Run
- **Serverless**: No server management required
- **Auto-scaling**: Scales to zero when idle (staging) or maintains 1 instance (prod)
- **Cost-effective**: Pay only for actual usage
- **HTTPS**: Automatic TLS certificates

### CI/CD: GitHub Actions
- **Automated**: Push to `main` → staging, push tag `v*` → production
- **Tested**: Build, test, and deploy in a single workflow
- **Secure**: Secrets managed by GitHub

### IaC: Terraform 1.6.x
- **Modular**: Reusable Cloud Run module
- **Environment-specific**: Different configs for staging vs prod
- **State tracking**: Local state files (upgrade to GCS for production)

## 🔧 Common Commands

```bash
# Local development
make build              # Build Docker image
make run                # Run locally on port 8080
make test               # Automated test

# Terraform
make staging-plan       # Preview staging changes
make staging-apply      # Deploy to staging manually
make prod-plan          # Preview production changes
make prod-apply         # Deploy to production manually

# Testing
curl http://localhost:8080/                    # Test local
curl $(terraform output -raw service_url)      # Test deployed
```

## 📚 Documentation

- **[DEPLOYMENT.md](./DEPLOYMENT.md)**: Complete setup and deployment guide
- **[TESTING.md](./TESTING.md)**: Testing, validation, and troubleshooting
- **[QUICKREF.md](./QUICKREF.md)**: Quick reference card
- **[IMPLEMENTATION.md](./IMPLEMENTATION.md)**: Architecture decisions and design

## 🎨 Design Decisions

### Why GCP Cloud Run?
- Simplest serverless container platform
- Built-in autoscaling and load balancing
- Generous free tier
- Native Docker support

### Why This Structure?
- **Modularity**: Cloud Run module is reusable
- **Separation**: Clear staging/production boundaries
- **DRY**: Environment configs reference shared module
- **Scalability**: Easy to add new environments

### Environment Configuration

| Feature | Staging | Production |
|---------|---------|------------|
| Service Name | `vida-interview-staging` | `vida-interview-prod` |
| Min Instances | 0 (scale to zero) | 1 (always available) |
| Max Instances | 5 | 20 |
| CPU | 1000m | 2000m |
| Memory | 512Mi | 1Gi |
| Deployment | On push to `main` | On tag `v*` |

## ✅ Deployment Validation

After deployment, verify:

```bash
# Get service URL
cd terraform/environments/staging
SERVICE_URL=$(terraform output -raw service_url)

# Test endpoint
curl $SERVICE_URL

# Expected response
{
  "service": "vida-interview",
  "env": "staging",
  "commit_sha": "abc1234",
  "timestamp": "2025-01-01T12:00:00.000000"
}
```

## 🔍 Monitoring

```bash
# View Cloud Run logs
gcloud run services logs read vida-interview-staging \
  --region=us-central1 \
  --limit=50

# Check service status
gcloud run services describe vida-interview-staging \
  --region=us-central1

# View all services
gcloud run services list --region=us-central1
```

## 🚨 Troubleshooting

See [TESTING.md](./TESTING.md) for detailed troubleshooting steps.

**Quick checks**:
```bash
# Verify GCP project
gcloud config get-value project

# Check enabled APIs
gcloud services list --enabled | grep -E 'run|container'

# Validate Terraform
cd terraform/environments/staging
terraform validate

# Check GitHub Actions
# Visit: https://github.com/<username>/vida-interview/actions
```

## 🔐 Security Notes

**Current implementation**:
- Service account with minimal required permissions
- Secrets stored in GitHub (not in code)
- `.gitignore` prevents credential leaks
- Public access (for demo purposes)

**Production recommendations**:
- Use Workload Identity Federation (no service account keys)
- Implement Cloud Armor for DDoS protection
- Use Cloud KMS for encryption
- Restrict public access with Cloud IAP
- Enable Cloud Audit Logs

## 💰 Cost Estimate

- **Staging**: ~$0-5/month (scales to zero)
- **Production**: ~$20-50/month (1 instance minimum, moderate traffic)
- **Container Registry**: ~$0.10/GB/month

Total: **~$25-55/month** for both environments

## 🎓 Interview Focus

This solution demonstrates:

1. **Infrastructure as Code**: Terraform best practices
2. **CI/CD Automation**: GitHub Actions workflows
3. **Container Orchestration**: Docker + Cloud Run
4. **Environment Management**: Staging/production separation
5. **Documentation**: Clear, comprehensive guides
6. **DevOps Practices**: Automation, testing, monitoring

## 📞 Support

- **Deployment Guide**: [DEPLOYMENT.md](./DEPLOYMENT.md)
- **Testing Guide**: [TESTING.md](./TESTING.md)
- **Quick Reference**: [QUICKREF.md](./QUICKREF.md)
- **GitHub Actions**: Check the Actions tab for build/deploy status
- **GCP Console**: View services at https://console.cloud.google.com/run

## 🎉 Next Steps After Interview

1. Migrate to GCS backend for Terraform state
2. Implement Workload Identity Federation
3. Add Cloud Monitoring dashboards
4. Set up alerting policies
5. Implement blue-green or canary deployments

---

**Time to deploy**: ~10 minutes from setup to live service  
**Maintenance**: Fully automated via GitHub Actions  
**Scalability**: Handles 0 to millions of requests
