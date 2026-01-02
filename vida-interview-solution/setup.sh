#!/bin/bash
set -e

echo "🚀 Vida Interview - GCP Setup Script"
echo "======================================"
echo ""

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo "❌ gcloud CLI not found. Please install: https://cloud.google.com/sdk/docs/install"
    exit 1
fi

# Check if terraform is installed
if ! command -v terraform &> /dev/null; then
    echo "❌ Terraform not found. Please install Terraform 1.6.x"
    exit 1
fi

# Get project ID
echo "📋 Current GCP Projects:"
gcloud projects list --format="table(projectId,name)"
echo ""

read -p "Enter your GCP Project ID: " PROJECT_ID

if [ -z "$PROJECT_ID" ]; then
    echo "❌ Project ID cannot be empty"
    exit 1
fi

echo ""
echo "Setting project to: $PROJECT_ID"
gcloud config set project $PROJECT_ID

echo ""
echo "🔧 Enabling required APIs..."
gcloud services enable run.googleapis.com
gcloud services enable containerregistry.googleapis.com
gcloud services enable iam.googleapis.com

echo ""
echo "👤 Creating service account..."
SA_NAME="vida-interview-deploy"
SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

# Check if service account exists
if gcloud iam service-accounts describe $SA_EMAIL &> /dev/null; then
    echo "Service account already exists: $SA_EMAIL"
else
    gcloud iam service-accounts create $SA_NAME \
        --display-name="Vida Interview Deploy Account"
    echo "✅ Service account created: $SA_EMAIL"
fi

echo ""
echo "🔐 Granting IAM permissions..."
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:${SA_EMAIL}" \
    --role="roles/run.admin" \
    --quiet

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:${SA_EMAIL}" \
    --role="roles/storage.admin" \
    --quiet

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:${SA_EMAIL}" \
    --role="roles/iam.serviceAccountUser" \
    --quiet

echo "✅ Permissions granted"

echo ""
echo "🔑 Creating service account key..."
KEY_FILE="vida-sa-key.json"

if [ -f "$KEY_FILE" ]; then
    read -p "⚠️  Key file already exists. Overwrite? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Skipping key creation"
        KEY_FILE=""
    fi
fi

if [ -n "$KEY_FILE" ]; then
    gcloud iam service-accounts keys create $KEY_FILE \
        --iam-account=$SA_EMAIL
    echo "✅ Key created: $KEY_FILE"
    echo ""
    echo "⚠️  IMPORTANT: Keep this key secure!"
    echo "⚠️  Add it to .gitignore (already included)"
fi

echo ""
echo "📝 Creating Terraform variable files..."

# Create staging tfvars
cat > terraform/environments/staging/terraform.tfvars <<EOF
project_id      = "${PROJECT_ID}"
region          = "us-central1"
container_image = "gcr.io/${PROJECT_ID}/vida-interview:latest"
commit_sha      = "$(git rev-parse --short HEAD 2>/dev/null || echo 'unknown')"
EOF
echo "✅ Created: terraform/environments/staging/terraform.tfvars"

# Create production tfvars
cat > terraform/environments/production/terraform.tfvars <<EOF
project_id      = "${PROJECT_ID}"
region          = "us-central1"
container_image = "gcr.io/${PROJECT_ID}/vida-interview:v1.0.0"
commit_sha      = "$(git rev-parse --short HEAD 2>/dev/null || echo 'unknown')"
EOF
echo "✅ Created: terraform/environments/production/terraform.tfvars"

echo ""
echo "🎯 Next Steps:"
echo "============="
echo ""
echo "1. Add GitHub Secrets (Settings → Secrets → Actions):"
echo "   - GCP_PROJECT_ID: ${PROJECT_ID}"
if [ -n "$KEY_FILE" ]; then
    echo "   - GCP_SA_KEY: (paste contents of ${KEY_FILE})"
fi
echo ""
echo "2. Test locally:"
echo "   make build"
echo "   make run"
echo ""
echo "3. Deploy manually (optional):"
echo "   make staging-apply"
echo ""
echo "4. Or push to main branch for automatic deployment:"
echo "   git add ."
echo "   git commit -m 'feat: initial deployment'"
echo "   git push origin main"
echo ""
echo "✅ Setup complete!"
