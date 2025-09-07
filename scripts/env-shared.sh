#!/bin/bash

export TF_VAR_organization_id="${TF_VAR_organization_id}"
export TF_VAR_billing_account="${TF_VAR_billing_account}"
export TF_VAR_folder_id="${TF_VAR_folder_id}"
export TF_VAR_project_prefix="${TF_VAR_project_prefix}"
export TF_VAR_version_suffix="${TF_VAR_version_suffix}"

# Development-specific domain (adds dev. prefix)
if [[ -n "${TF_VAR_domain_name}" ]]; then
    export TF_VAR_domain_name="${TF_VAR_domain_name}"
else
    echo "Warning: TF_VAR_domain_name not set in base environment"
fi

echo "🔧 Shared environment configured"
echo "   Domain: ${TF_VAR_domain_name}"
echo "   Org ID: ${TF_VAR_organization_id}"
echo "   Folder ID: ${TF_VAR_folder_id}"
echo "   Project Prefix: ${TF_VAR_project_prefix}"
echo "   Version Suffix: ${TF_VAR_version_suffix}"
