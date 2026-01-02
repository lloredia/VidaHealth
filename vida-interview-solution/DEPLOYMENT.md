# Vida Infrastructure Interview - Solution

A containerized Flask API deployed to GCP Cloud Run with Terraform infrastructure as code and GitHub Actions CI/CD.

## Architecture Overview

- **Application**: Flask API containerized with Docker
- **Infrastructure**: GCP Cloud Run managed via Terraform
- **CI/CD**: GitHub Actions for automated build and deployment
- **Environments**: 
  - `staging` - Auto-deployed from `main` branch
  - `prod` - Auto-deployed from `v*` tags

## Quick Start

### Prerequisites

1. **GCP Account** with billing enabled
2. **GCP Project** created
3. **Required APIs enabled**:
   ```bash
   gcloud services enable run.googleapis.com
   gcloud services enable containerregistry.googleapis.com
   ```
4. **Terraform 1.6.x** installed:
   ```bash
   brew install terraform@1.6
   brew link --force terraform@1.6
   ```
5. **Docker** installed
6. **GitHub repository** forked

### Local Development

Run the application locally:

```bash
# Build the image
docker build -t vida-interview .

# Run the container
docker run --rm -p 8080:8080 \
  -e SERVICE_NAME=vida-interview \
  -e GIT_COMMIT_SHA=$(git rev-parse --short HEAD) \
  -e APP_ENV=local \
  vida-interview

# Test the endpoint
curl http://localhost:8080/
```

Expected response:
```json
{
  "service": "vida-interview",
  "env": "local",
  "commit_sha": "abc1234",
  "timestamp": "2025-01-01T12:00:00.000000"
}
```

## Infrastructure Setup

### 1. Create GCP Service Account

```bash
# Set your project ID
export PROJECT_ID="your-gcp-project-id"
gcloud config set project ${PROJECT_ID}

# Create service account
gcloud iam service-accounts create vida-interview-deploy \
  --display-name="Vida Interview Deploy Account"

# Grant necessary permissions
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:vida-interview-deploy@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/run.admin"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:vida-interview-deploy@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/storage.admin"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:vida-interview-deploy@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/iam.serviceAccountUser"

# Create and download key
gcloud iam service-accounts keys create vida-sa-key.json \
  --iam-account=vida-interview-deploy@${PROJECT_ID}.iam.gserviceaccount.com
```

### 2. Configure GitHub Secrets

Add these secrets to your GitHub repository (Settings → Secrets and variables → Actions):

- `GCP_PROJECT_ID`: Your GCP project ID
- `GCP_SA_KEY`: Contents of `vida-sa-key.json` file

### 3. Manual Terraform Deployment (Optional)

For staging:
```bash
cd terraform/environments/staging

# Copy example vars
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your values
# project_id, region, container_image, commit_sha

# Initialize Terraform
terraform init

# Plan deployment
terraform plan

# Apply infrastructure
terraform apply
```

For production:
```bash
cd terraform/environments/production

# Same process as staging
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars
terraform init
terraform plan
terraform apply
```

## CI/CD Pipeline

### Automated Deployment

The GitHub Actions pipeline automatically:

1. **On push to `main`**:
   - Builds Docker image
   - Pushes to GCR with tag `staging-{commit-sha}`
   - Deploys to staging environment

2. **On tag `v*`** (e.g., `v1.0.0`):
   - Builds Docker image
   - Pushes to GCR with version tag
   - Deploys to production environment

3. **On Pull Requests**:
   - Validates Docker build
   - Tests the application
   - Validates Terraform formatting and syntax

### Deployment Workflow

```bash
# Deploy to staging
git add .
git commit -m "feat: new feature"
git push origin main

# Deploy to production
git tag v1.0.0
git push origin v1.0.0
```

### Workflow Files

- `.github/workflows/deploy.yml` - Main CI/CD pipeline
- `.github/workflows/pr-validation.yml` - PR validation

## Project Structure

```
.
├── .github/
│   └── workflows/
│       ├── deploy.yml           # Main CI/CD pipeline
│       └── pr-validation.yml    # PR checks
├── terraform/
│   ├── modules/
│   │   └── cloud-run/          # Reusable Cloud Run module
│   │       ├── main.tf
│   │       ├── variables.tf
│   │       └── outputs.tf
│   └── environments/
│       ├── staging/            # Staging environment
│       │   ├── main.tf
│       │   ├── variables.tf
│       │   ├── outputs.tf
│       │   └── terraform.tfvars.example
│       └── production/         # Production environment
│           ├── main.tf
│           ├── variables.tf
│           ├── outputs.tf
│           └── terraform.tfvars.example
├── app.py                      # Flask application
├── Dockerfile                  # Container definition
└── requirements.txt            # Python dependencies
```

## Environment Configuration

### Staging
- Service Name: `vida-interview-staging`
- Resources: 1 CPU, 512Mi memory
- Scaling: 0-5 instances
- Auto-deploy: `main` branch

### Production
- Service Name: `vida-interview-prod`
- Resources: 2 CPU, 1Gi memory
- Scaling: 1-20 instances (min 1 for availability)
- Auto-deploy: `v*` tags

## Monitoring and Validation

### Check Deployment Status

View in GitHub Actions:
- Go to Actions tab in your repository
- Check the latest workflow run

### Test Deployed Service

```bash
# Get service URL from Terraform output
cd terraform/environments/staging
terraform output service_url

# Test the endpoint
curl $(terraform output -raw service_url)
```

### View Logs

```bash
# View Cloud Run logs
gcloud run services logs read vida-interview-staging \
  --region=us-central1 \
  --limit=50
```

## Troubleshooting

### Docker Build Fails
- Ensure all dependencies are in `requirements.txt`
- Check Dockerfile syntax
- Verify base image is accessible

### Terraform Apply Fails
- Check GCP credentials are valid
- Verify service account has required permissions
- Ensure required APIs are enabled
- Check state file isn't corrupted

### GitHub Actions Fails
- Verify `GCP_PROJECT_ID` and `GCP_SA_KEY` secrets are set
- Check service account permissions
- Review workflow logs for specific errors

### Service Not Accessible
- Verify IAM policy allows public access (or adjust as needed)
- Check Cloud Run service is deployed successfully
- Ensure no VPC/firewall rules blocking traffic

## Security Considerations

**For Production**:
- Store state in GCS with encryption
- Use Workload Identity instead of service account keys
- Implement proper IAM policies (remove public access if needed)
- Enable Cloud Run authentication
- Add Cloud Armor for DDoS protection
- Implement secrets management (Secret Manager)
- Add vulnerability scanning

## Cost Optimization

- Staging scales to zero when idle
- Production maintains 1 instance for availability
- Adjust `min_instances` and `max_instances` based on traffic
- Monitor billing in GCP Console

## Next Steps

- [ ] Enable Cloud Logging and Monitoring
- [ ] Add health check endpoints
- [ ] Implement custom domains with Cloud Load Balancer
- [ ] Set up GCS backend for Terraform state
- [ ] Add integration tests
- [ ] Implement canary deployments
- [ ] Add Slack/email notifications for deployments

## Support

For issues or questions:
1. Check GitHub Actions logs
2. Review Terraform state
3. Check GCP Cloud Console for service status
4. Review Cloud Run logs
