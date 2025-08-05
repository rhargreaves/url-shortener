#!/bin/bash

# Production environment configuration
# Source this file for production: source scripts/env-prod.sh

# Required Terraform variables
export TF_VAR_organization_id="${TF_VAR_organization_id}"
export TF_VAR_billing_account="${TF_VAR_billing_account}"
export TF_VAR_folder_id="${TF_VAR_folder_id}"
export TF_VAR_project_prefix="${TF_VAR_project_prefix:-}"
export TF_VAR_version_suffix="${TF_VAR_version_suffix:-}"

# Production uses the base domain as-is
export TF_VAR_domain_name="${TF_VAR_domain_name}"

echo "🚀 Production environment configured"
echo "   Domain: ${TF_VAR_domain_name}"
echo "   Org ID: ${TF_VAR_organization_id}"
echo "   Project Prefix: ${TF_VAR_project_prefix}"
echo "   Version Suffix: ${TF_VAR_version_suffix}"
