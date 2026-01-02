# Testing & Validation Guide

This guide covers local testing, deployment validation, and troubleshooting.

## Local Testing

### Build and Run Locally

```bash
# Using Make
make build
make run

# Or manually
docker build -t vida-interview:local .
docker run --rm -p 8080:8080 \
  -e SERVICE_NAME=vida-interview \
  -e APP_ENV=local \
  -e GIT_COMMIT_SHA=$(git rev-parse --short HEAD) \
  vida-interview:local
```

### Test Endpoints

```bash
# Health check
curl http://localhost:8080/

# Expected response
{
  "service": "vida-interview",
  "env": "local",
  "commit_sha": "abc1234",
  "timestamp": "2025-01-01T12:00:00.000000"
}

# Formatted output
curl -s http://localhost:8080/ | jq .
```

### Automated Local Test

```bash
make test
```

## Terraform Validation

### Validate Syntax

```bash
# Check formatting
terraform fmt -check -recursive terraform/

# Fix formatting
terraform fmt -recursive terraform/

# Validate staging
cd terraform/environments/staging
terraform init -backend=false
terraform validate

# Validate production
cd terraform/environments/production
terraform init -backend=false
terraform validate
```

### Dry Run (Plan)

```bash
# Staging
cd terraform/environments/staging
terraform init
terraform plan

# Production
cd terraform/environments/production
terraform init
terraform plan
```

## Deployment Testing

### Staging Deployment

```bash
# Push to main branch
git checkout main
git add .
git commit -m "test: staging deployment"
git push origin main

# Monitor in GitHub Actions
# https://github.com/<your-username>/vida-interview/actions

# Wait for deployment to complete (~3-5 minutes)

# Get service URL
cd terraform/environments/staging
terraform output service_url

# Test deployed service
curl $(terraform output -raw service_url)
```

### Production Deployment

```bash
# Create and push tag
git tag v1.0.0
git push origin v1.0.0

# Monitor in GitHub Actions
# Wait for deployment (~3-5 minutes)

# Test deployed service
cd terraform/environments/production
curl $(terraform output -raw service_url)
```

## Validation Checklist

### Pre-Deployment

- [ ] Docker image builds successfully
- [ ] Local container runs without errors
- [ ] Endpoint returns valid JSON
- [ ] Terraform configuration is valid
- [ ] All required secrets are configured in GitHub
- [ ] GCP APIs are enabled
- [ ] Service account has correct permissions

### Post-Deployment

- [ ] GitHub Actions workflow completed successfully
- [ ] Cloud Run service is running (check GCP Console)
- [ ] Service URL is accessible
- [ ] Response includes correct environment
- [ ] Response includes commit SHA
- [ ] Logs are available in Cloud Run
- [ ] No errors in Cloud Run logs

## Monitoring Commands

### Check Service Status

```bash
# List Cloud Run services
gcloud run services list --region=us-central1

# Describe specific service
gcloud run services describe vida-interview-staging \
  --region=us-central1

# Get service URL
gcloud run services describe vida-interview-staging \
  --region=us-central1 \
  --format='value(status.url)'
```

### View Logs

```bash
# Recent logs
gcloud run services logs read vida-interview-staging \
  --region=us-central1 \
  --limit=50

# Follow logs in real-time
gcloud run services logs tail vida-interview-staging \
  --region=us-central1

# Filter by severity
gcloud run services logs read vida-interview-staging \
  --region=us-central1 \
  --log-filter='severity>=ERROR'
```

### Check Deployment History

```bash
# List revisions
gcloud run revisions list \
  --service=vida-interview-staging \
  --region=us-central1

# Describe specific revision
gcloud run revisions describe <revision-name> \
  --region=us-central1
```

## Troubleshooting

### Common Issues

#### 1. Docker Build Fails

**Symptom**: `docker build` command fails

**Solutions**:
```bash
# Check Dockerfile syntax
docker build --no-cache -t vida-interview:test .

# Verify requirements.txt
cat requirements.txt

# Check base image
docker pull python:3.11-slim
```

#### 2. Container Starts But Crashes

**Symptom**: Container exits immediately

**Solutions**:
```bash
# Check logs
docker logs <container-id>

# Run with interactive shell
docker run -it --rm vida-interview:local /bin/bash

# Verify port binding
docker run --rm -p 8080:8080 vida-interview:local

# Check environment variables
docker run --rm vida-interview:local env
```

#### 3. Terraform Apply Fails

**Symptom**: `terraform apply` returns errors

**Solutions**:
```bash
# Check credentials
gcloud auth list
gcloud config get-value project

# Verify service account
gcloud iam service-accounts describe \
  vida-interview-deploy@${PROJECT_ID}.iam.gserviceaccount.com

# Check API enablement
gcloud services list --enabled | grep -E 'run|container'

# Reinitialize Terraform
rm -rf .terraform
terraform init

# Check state lock
rm -f .terraform.tfstate.lock.info
```

#### 4. GitHub Actions Fails

**Symptom**: Workflow fails in GitHub Actions

**Solutions**:
1. Check secrets are set correctly
2. Verify service account JSON is valid
3. Check workflow logs for specific error
4. Ensure GCP APIs are enabled
5. Verify service account permissions

```bash
# Test service account locally
gcloud auth activate-service-account \
  --key-file=vida-sa-key.json

# List permissions
gcloud projects get-iam-policy ${PROJECT_ID} \
  --flatten="bindings[].members" \
  --filter="bindings.members:serviceAccount:vida-interview-deploy@*"
```

#### 5. Service Not Accessible

**Symptom**: Cannot access deployed service URL

**Solutions**:
```bash
# Check service is deployed
gcloud run services list --region=us-central1

# Verify IAM policy
gcloud run services get-iam-policy vida-interview-staging \
  --region=us-central1

# Add public access if missing
gcloud run services add-iam-policy-binding vida-interview-staging \
  --region=us-central1 \
  --member="allUsers" \
  --role="roles/run.invoker"

# Check for errors
gcloud run services logs read vida-interview-staging \
  --region=us-central1 \
  --limit=20
```

#### 6. Wrong Environment Deployed

**Symptom**: Service shows wrong `env` value

**Solutions**:
- Verify branch/tag naming
- Check GitHub Actions environment detection
- Manually verify Terraform variables
- Check Cloud Run environment variables

```bash
# Check deployed environment variables
gcloud run services describe vida-interview-staging \
  --region=us-central1 \
  --format='value(spec.template.spec.containers[0].env)'
```

## Performance Testing

### Load Test (Simple)

```bash
# Install Apache Bench (if not available)
# macOS: brew install httpd
# Ubuntu: apt-get install apache2-utils

# Test with 100 requests, 10 concurrent
ab -n 100 -c 10 $(terraform output -raw service_url)

# More detailed load test
ab -n 1000 -c 50 -g results.tsv $(terraform output -raw service_url)
```

### Verify Auto-Scaling

```bash
# Monitor instances during load
watch -n 2 'gcloud run revisions list \
  --service=vida-interview-staging \
  --region=us-central1 \
  --format="table(metadata.name,status.conditions.status)"'
```

## Clean Up

### Remove Deployed Services

```bash
# Delete staging
cd terraform/environments/staging
terraform destroy

# Delete production
cd terraform/environments/production
terraform destroy

# Or manually
gcloud run services delete vida-interview-staging \
  --region=us-central1 \
  --quiet

gcloud run services delete vida-interview-prod \
  --region=us-central1 \
  --quiet
```

### Remove Local Resources

```bash
make clean

# Or manually
docker rmi vida-interview:local
docker system prune -a
```

## Security Testing

### Container Scanning

```bash
# Scan for vulnerabilities (requires Docker Scout or Trivy)
docker scout cves vida-interview:local

# Or with Trivy
trivy image vida-interview:local
```

### IAM Audit

```bash
# Check service account permissions
gcloud projects get-iam-policy ${PROJECT_ID} \
  --flatten="bindings[].members" \
  --filter="bindings.members:serviceAccount:vida-interview-deploy@*" \
  --format="table(bindings.role)"
```

## Continuous Validation

### Set Up Monitoring

1. Navigate to GCP Console → Cloud Run
2. Select your service
3. Click "Logs" tab
4. Set up log-based metrics
5. Create alerting policies

### Health Check Script

```bash
#!/bin/bash
# health-check.sh

URL=$1
if [ -z "$URL" ]; then
    echo "Usage: ./health-check.sh <service-url>"
    exit 1
fi

RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" $URL)

if [ "$RESPONSE" = "200" ]; then
    echo "✅ Service is healthy (HTTP $RESPONSE)"
    curl -s $URL | jq .
    exit 0
else
    echo "❌ Service is unhealthy (HTTP $RESPONSE)"
    exit 1
fi
```

Usage:
```bash
chmod +x health-check.sh
./health-check.sh https://vida-interview-staging-xxx.run.app
```
