#!/bin/bash

# URL Shortener Infrastructure Validation Script
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

# Check if running from project root
check_project_root() {
    if [[ ! -f "README.md" ]] || [[ ! -d "infra" ]] || [[ ! -d "k8s" ]]; then
        log_error "Please run this script from the project root directory"
        exit 1
    fi
}

# Validate Terraform configuration
validate_terraform() {
    log_info "Validating Terraform configuration..."

    local error_count=0

    # Validate main configuration
    cd infra
    if ! terraform validate; then
        log_error "Main Terraform configuration is invalid"
        ((error_count++))
    fi
    cd ..

    # Validate development environment
    cd infra/environments/dev
    if ! terraform validate; then
        log_error "Development environment configuration is invalid"
        ((error_count++))
    fi
    cd ../../..

    # Validate production environment
    cd infra/environments/prod
    if ! terraform validate; then
        log_error "Production environment configuration is invalid"
        ((error_count++))
    fi
    cd ../../..

    if [[ $error_count -eq 0 ]]; then
        log_info "Terraform validation passed"
    else
        log_error "Terraform validation failed with $error_count errors"
        return 1
    fi
}

# Validate Kubernetes manifests
validate_kubernetes() {
    log_info "Validating Kubernetes manifests..."

    local error_count=0

    # Find all YAML files in k8s directory
    while IFS= read -r -d '' file; do
        log_info "Validating $file"
        if ! kubectl apply --dry-run=client -f "$file" >/dev/null 2>&1; then
            log_error "Invalid Kubernetes manifest: $file"
            ((error_count++))
        fi
    done < <(find k8s -name "*.yaml" -type f -print0)

    if [[ $error_count -eq 0 ]]; then
        log_info "Kubernetes manifest validation passed"
    else
        log_error "Kubernetes manifest validation failed with $error_count errors"
        return 1
    fi
}

# Check required tools
check_tools() {
    log_info "Checking required tools..."

    local tools=("terraform" "kubectl" "gcloud" "docker")
    local missing_tools=()

    for tool in "${tools[@]}"; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            missing_tools+=("$tool")
        fi
    done

    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        log_error "Missing required tools: ${missing_tools[*]}"
        log_error "Please install the missing tools and try again"
        return 1
    else
        log_info "All required tools are available"
    fi
}

# Check Terraform formatting
check_terraform_format() {
    log_info "Checking Terraform formatting..."

    if ! terraform fmt -check=true -recursive infra/; then
        log_warn "Terraform files are not properly formatted"
        log_info "Run 'terraform fmt -recursive infra/' to fix formatting"
        return 1
    else
        log_info "Terraform formatting is correct"
    fi
}

# Validate configuration files
validate_config_files() {
    log_info "Validating configuration files..."

    local required_files=(
        "infra/environments/dev/terraform.tfvars"
        "infra/environments/prod/terraform.tfvars"
        "cloudbuild.yaml"
        "Dockerfile"
        "Makefile"
    )

    local missing_files=()

    for file in "${required_files[@]}"; do
        if [[ ! -f "$file" ]]; then
            missing_files+=("$file")
        fi
    done

    if [[ ${#missing_files[@]} -gt 0 ]]; then
        log_error "Missing required configuration files: ${missing_files[*]}"
        return 1
    else
        log_info "All required configuration files are present"
    fi
}

# Check for common issues
check_common_issues() {
    log_info "Checking for common configuration issues..."

    local issues=()

    # Check for placeholder values in tfvars
    if grep -q "123456789012" infra/environments/*/terraform.tfvars; then
        issues+=("Found placeholder organization ID in terraform.tfvars")
    fi

    if grep -q "012345-678901-234567" infra/environments/*/terraform.tfvars; then
        issues+=("Found placeholder billing account in terraform.tfvars")
    fi

    if grep -q "short.example.com" infra/environments/*/terraform.tfvars; then
        issues+=("Found placeholder domain name in terraform.tfvars")
    fi

    # Check for PROJECT_ID placeholder in k8s manifests
    if grep -q "PROJECT_ID" k8s/*.yaml; then
        issues+=("Found PROJECT_ID placeholder in Kubernetes manifests")
    fi

    if [[ ${#issues[@]} -gt 0 ]]; then
        log_warn "Found potential configuration issues:"
        for issue in "${issues[@]}"; do
            log_warn "  - $issue"
        done
        log_warn "Please review and update these placeholders"
    else
        log_info "No common configuration issues found"
    fi
}

# Main validation function
main() {
    log_info "Starting URL Shortener infrastructure validation..."

    local validation_errors=0

    check_project_root || ((validation_errors++))
    check_tools || ((validation_errors++))
    validate_config_files || ((validation_errors++))
    check_terraform_format || ((validation_errors++))
    validate_terraform || ((validation_errors++))
    validate_kubernetes || ((validation_errors++))
    check_common_issues

    if [[ $validation_errors -eq 0 ]]; then
        log_info "✅ All validations passed! Infrastructure is ready for deployment."
    else
        log_error "❌ Validation failed with $validation_errors errors. Please fix the issues and try again."
        exit 1
    fi
}

# Run main function
main "$@"