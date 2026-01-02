# Vida Interview - Implementation Checklist

Use this checklist to implement the solution in your forked repository.

## ⏱️ Time Estimate: 10-15 minutes

---

## Phase 1: Setup (5 minutes)

### Step 1: Extract Files
- [ ] Download `vida-interview-solution.tar.gz`
- [ ] Extract to your forked `vida-interview` repository
- [ ] Verify all files are present

```bash
cd vida-interview
tar -xzf /path/to/vida-interview-solution.tar.gz --strip-components=1
ls -la
```

### Step 2: GCP Setup
- [ ] Ensure you have a GCP project
- [ ] Run the automated setup script

```bash
chmod +x setup.sh
./setup.sh
```

The script will:
- Enable required GCP APIs
- Create service account
- Grant IAM permissions
- Generate service account key
- Create Terraform variable files

### Step 3: GitHub Configuration
- [ ] Go to your repository Settings → Secrets and variables → Actions
- [ ] Add secret: `GCP_PROJECT_ID` = your GCP project ID
- [ ] Add secret: `GCP_SA_KEY` = full contents of `vida-sa-key.json`

**⚠️ Important**: Copy the entire JSON file contents, including braces

---

## Phase 2: Test Locally (3 minutes)

### Step 4: Local Build
- [ ] Build Docker image

```bash
make build
```

### Step 5: Local Run
- [ ] Run container locally

```bash
make run
```

### Step 6: Test Endpoint
- [ ] Test in another terminal

```bash
curl http://localhost:8080/
```

Expected response:
```json
{
  "service": "vida-interview",
  "env": "local",
  "commit_sha": "...",
  "timestamp": "..."
}
```

---

## Phase 3: Deploy (5 minutes)

### Step 7: Commit & Push
- [ ] Commit all files

```bash
git add .
git commit -m "feat: add Terraform infrastructure and CI/CD pipeline"
```

- [ ] Push to trigger staging deployment

```bash
git push origin main
```

### Step 8: Monitor Deployment
- [ ] Go to GitHub Actions tab
- [ ] Watch the workflow run (~3-5 minutes)
- [ ] Verify "Build and Push" job succeeds
- [ ] Verify "Deploy" job succeeds
- [ ] Note the service URL in the job summary

### Step 9: Verify Staging
- [ ] Get service URL

```bash
cd terraform/environments/staging
terraform output service_url
```

- [ ] Test deployed service

```bash
curl $(terraform output -raw service_url)
```

Expected response:
```json
{
  "service": "vida-interview",
  "env": "staging",
  "commit_sha": "...",
  "timestamp": "..."
}
```

---

## Phase 4: Production Deploy (2 minutes)

### Step 10: Create Production Tag
- [ ] Create version tag

```bash
git tag v1.0.0
```

- [ ] Push tag

```bash
git push origin v1.0.0
```

### Step 11: Monitor Production Deployment
- [ ] Watch GitHub Actions
- [ ] Verify deployment succeeds
- [ ] Note production service URL

### Step 12: Verify Production
- [ ] Test production service

```bash
cd terraform/environments/production
curl $(terraform output -raw service_url)
```

---

## Phase 5: Validation (2 minutes)

### Step 13: Check Cloud Run Console
- [ ] Open GCP Console → Cloud Run
- [ ] Verify `vida-interview-staging` is running
- [ ] Verify `vida-interview-prod` is running
- [ ] Check logs for any errors

### Step 14: Review Metrics
- [ ] Check request counts
- [ ] Check instance counts
- [ ] Verify auto-scaling behavior

### Step 15: Final Checks
- [ ] Both environments accessible via HTTPS
- [ ] Correct environment names in responses
- [ ] Commit SHAs match
- [ ] No errors in logs

---

## ✅ Success Criteria

You've successfully completed the implementation if:

- [x] Both staging and production environments are deployed
- [x] GitHub Actions workflows are running successfully
- [x] Service endpoints return valid JSON
- [x] Environment values are correct (staging/prod)
- [x] Commit SHAs are present in responses
- [x] Cloud Run services visible in GCP Console
- [x] No errors in application logs

---

## 📋 Troubleshooting Quick Reference

### GitHub Actions Fails
1. Check secrets are set: `GCP_PROJECT_ID`, `GCP_SA_KEY`
2. Verify service account has permissions
3. Check GCP APIs are enabled
4. Review workflow logs for specific errors

### Terraform Apply Fails
1. Verify GCP credentials: `gcloud auth list`
2. Check project is set: `gcloud config get-value project`
3. Ensure APIs are enabled: `gcloud services list --enabled`
4. Review Terraform logs

### Service Not Accessible
1. Check service is deployed: `gcloud run services list`
2. Verify IAM policy allows access
3. Review Cloud Run logs: `gcloud run services logs read ...`
4. Test from GCP Console

### Local Build Issues
1. Ensure Docker is running: `docker ps`
2. Check Dockerfile syntax
3. Verify requirements.txt exists
4. Rebuild without cache: `docker build --no-cache ...`

---

## 📚 Documentation Reference

- **README.md**: Project overview and quick start
- **DEPLOYMENT.md**: Complete deployment guide
- **TESTING.md**: Testing and troubleshooting
- **IMPLEMENTATION.md**: Architecture decisions
- **QUICKREF.md**: Quick reference card
- **SUMMARY.md**: Executive summary

---

## 🎯 Time Check

Expected completion time for each phase:
- ✅ Phase 1 (Setup): 5 minutes
- ✅ Phase 2 (Local Test): 3 minutes  
- ✅ Phase 3 (Deploy): 5 minutes
- ✅ Phase 4 (Production): 2 minutes
- ✅ Phase 5 (Validation): 2 minutes

**Total: ~15-20 minutes from zero to production**

---

## 🚀 What's Next?

After successful deployment, consider:

1. **Review documentation** - Read IMPLEMENTATION.md for design decisions
2. **Explore Terraform** - Examine module structure and variables
3. **Check workflows** - Review GitHub Actions YAML files
4. **Monitor costs** - Set up billing alerts in GCP
5. **Plan enhancements** - See IMPLEMENTATION.md for next steps

---

## ✨ You're Done!

Congratulations! You now have a fully automated, production-ready infrastructure pipeline.

**What you've built:**
- ✅ Serverless containerized application
- ✅ Infrastructure as Code (Terraform)
- ✅ Automated CI/CD (GitHub Actions)
- ✅ Staging and production environments
- ✅ Comprehensive documentation

Ready for the interview! 🎉
