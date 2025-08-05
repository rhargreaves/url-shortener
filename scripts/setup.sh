#!/bin/bash

# URL Shortener Infrastructure Setup Script
set -euo pipefail

# Configuration
PROJECT_PREFIX="${PROJECT_PREFIX:-}"
REGION="${REGION:-}"
ORG_ID="${ORG_ID:-}"
BILLING_ACCOUNT="${BILLING_ACCOUNT:-}"
FOLDER_ID="${FOLDER_ID:-}"

VERSION_SUFFIX="${VERSION_SUFFIX:-v2}"
PROJECT_SHARED_NETWORK_ID="${PROJECT_PREFIX}-shared-network-${VERSION_SUFFIX}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."

    command -v gcloud >/dev/null 2>&1 || { log_error "gcloud CLI is required but not installed."; exit 1; }
    command -v terraform >/dev/null 2>&1 || { log_error "Terraform is required but not installed."; exit 1; }
    command -v kubectl >/dev/null 2>&1 || { log_error "kubectl is required but not installed."; exit 1; }

    if [[ -z "$ORG_ID" ]]; then
        log_error "ORG_ID environment variable is required"
        exit 1
    fi

    if [[ -z "$BILLING_ACCOUNT" ]]; then
        log_error "BILLING_ACCOUNT environment variable is required"
        exit 1
    fi

    if [[ -n "$FOLDER_ID" ]]; then
        log_info "Using folder: $FOLDER_ID"
    else
        log_info "Using organization: $ORG_ID"
    fi

    log_info "Prerequisites check passed"
}

# Setup gcloud authentication
setup_auth() {
    log_info "Setting up authentication..."

    if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
        log_info "No active gcloud authentication found. Please run 'gcloud auth login'"
        gcloud auth login
    else
        log_info "Active gcloud authentication found"
    fi

    # Check if application default credentials exist
    if ! gcloud auth application-default print-access-token >/dev/null 2>&1; then
        log_info "No application default credentials found. Setting up..."
        gcloud auth application-default login
    else
        log_info "Application default credentials already configured"
    fi

    log_info "Authentication setup complete"
}

# Create initial projects for state management
create_state_projects() {
    log_info "Creating projects for Terraform state management..."

    # Check if shared network project already exists
    if gcloud projects describe "$PROJECT_SHARED_NETWORK_ID" >/dev/null 2>&1; then
        log_info "Project $PROJECT_SHARED_NETWORK_ID already exists"
    else
        log_info "Creating project $PROJECT_SHARED_NETWORK_ID"

        if [[ -n "$FOLDER_ID" && "$FOLDER_ID" != "" ]]; then
            gcloud projects create "$PROJECT_SHARED_NETWORK_ID" \
                --folder="$FOLDER_ID"
        else
            gcloud projects create "$PROJECT_SHARED_NETWORK_ID" \
                --organization="$ORG_ID"
        fi
    fi

    # Link billing account
    gcloud billing projects link "$PROJECT_SHARED_NETWORK_ID" \
        --billing-account="$BILLING_ACCOUNT"

    # Enable required APIs
    gcloud services enable storage.googleapis.com \
        --project="$PROJECT_SHARED_NETWORK_ID"

    log_info "State management projects setup complete"
}

# Create Terraform state buckets
create_state_buckets() {
    log_info "Creating Terraform state buckets..."

    local dev_bucket="gs://${PROJECT_PREFIX}-terraform-state-dev-${VERSION_SUFFIX}"
    local prod_bucket="gs://${PROJECT_PREFIX}-terraform-state-prod-${VERSION_SUFFIX}"

    # Check and create dev bucket
    if gsutil ls "$dev_bucket" >/dev/null 2>&1; then
        log_info "Dev bucket $dev_bucket already exists"
    else
        log_info "Creating dev bucket $dev_bucket"
        gsutil mb -p "$PROJECT_SHARED_NETWORK_ID" "$dev_bucket"
    fi

    # Check and create prod bucket
    if gsutil ls "$prod_bucket" >/dev/null 2>&1; then
        log_info "Prod bucket $prod_bucket already exists"
    else
        log_info "Creating prod bucket $prod_bucket"
        gsutil mb -p "$PROJECT_SHARED_NETWORK_ID" "$prod_bucket"
    fi

    # Enable versioning
    gsutil versioning set on "$dev_bucket"
    gsutil versioning set on "$prod_bucket"

    log_info "Terraform state buckets setup complete"
}

# Initialize Terraform
init_terraform() {
    log_info "Initializing Terraform..."

    cd infra
    terraform init

    cd environments/dev
    terraform init

    cd ../prod
    terraform init

    cd ../../..

    log_info "Terraform initialization complete"
}

# Update configuration files
update_config() {
    log_info "Setting up environment variables..."

    # Create .env file from template
    if [[ ! -f ".env" ]]; then
        cp .env.example .env

        # Update .env with actual values
        sed -i.bak "s/TF_VAR_organization_id=\"123456789012\"/TF_VAR_organization_id=\"$ORG_ID\"/" .env
        sed -i.bak "s/TF_VAR_billing_account=\"012345-678901-234567\"/TF_VAR_billing_account=\"$BILLING_ACCOUNT\"/" .env

        log_info "Created .env file with your configuration"
        log_warn "Review and customize .env file as needed"
    else
        log_info ".env file already exists, skipping"
    fi

    log_info "Configuration files updated"
}

# Main execution
main() {
    log_info "Starting URL Shortener infrastructure setup..."

    check_prerequisites
    setup_auth
    create_state_projects
    create_state_buckets
    update_config
    init_terraform

    log_info "Setup complete! Next steps:"
    echo "1. Source the environment: source .env"
    echo "2. Review and customize .env file with your specific values"
    echo "3. Run 'make plan-dev' to review the development infrastructure plan"
    echo "4. Run 'make apply-dev' to create the development infrastructure"
    echo "5. Repeat for production environment with 'make plan-prod' and 'make apply-prod'"
}

# Run main function
main "$@"
