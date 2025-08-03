#!/bin/bash

# Simple environment setup script for TF_VAR_ variables
set -euo pipefail

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

# Check if .env file exists
if [[ -f ".env" ]]; then
    log_info "Loading environment variables from .env file..."
    source .env
else
    log_warn ".env file not found. Creating from template..."
    if [[ -f ".env.example" ]]; then
        cp .env.example .env
        log_info "Created .env from .env.example"
        log_warn "Please edit .env with your actual values before proceeding"
        exit 1
    else
        log_error "No .env.example file found. Please create .env manually."
        exit 1
    fi
fi

# Validate required variables
required_vars=("TF_VAR_organization_id" "TF_VAR_billing_account")
missing_vars=()

for var in "${required_vars[@]}"; do
    if [[ -z "${!var:-}" ]]; then
        missing_vars+=("$var")
    fi
done

if [[ ${#missing_vars[@]} -gt 0 ]]; then
    log_error "Missing required environment variables in .env:"
    for var in "${missing_vars[@]}"; do
        log_error "  - $var"
    done
    log_error "Please edit .env and set these variables"
    exit 1
fi

# Show current configuration
log_info "Current Terraform configuration:"
echo "  Organization ID: $TF_VAR_organization_id"
echo "  Billing Account: $TF_VAR_billing_account"
if [[ -n "${TF_VAR_folder_id:-}" ]]; then
    echo "  Folder ID: $TF_VAR_folder_id"
fi

log_info "✅ Environment setup complete!"
log_info "You can now run: make plan-dev or make plan-prod"