#!/bin/bash

# GitHub Actions Service Account Setup Script
set -euo pipefail

# Configuration
PROJECT_PREFIX="${PROJECT_PREFIX:-}"
VERSION_SUFFIX="${VERSION_SUFFIX:-}"
ORG_ID="${ORG_ID:-}"
FOLDER_ID="${FOLDER_ID:-}"
SA_PROJECT="${SA_PROJECT:-}" # Allow override for service account project

# Derived values
SHARED_NETWORK_PROJECT="${PROJECT_PREFIX}-shared-network-${VERSION_SUFFIX}"
SA_NAME="github-actions"

# Determine the project for the service account
if [[ -n "$SA_PROJECT" ]]; then
    SA_EMAIL="${SA_NAME}@${SA_PROJECT}.iam.gserviceaccount.com"
    SA_PROJECT_ID="$SA_PROJECT"
else
    # Default to using gcloud's default project if available
    DEFAULT_PROJECT=$(gcloud config get-value project 2>/dev/null || echo "")
    if [[ -n "$DEFAULT_PROJECT" ]]; then
        SA_EMAIL="${SA_NAME}@${DEFAULT_PROJECT}.iam.gserviceaccount.com"
        SA_PROJECT_ID="$DEFAULT_PROJECT"
        log_info "Using default gcloud project for service account: $DEFAULT_PROJECT"
    else
        # Fallback to shared network project
        SA_EMAIL="${SA_NAME}@${SHARED_NETWORK_PROJECT}.iam.gserviceaccount.com"
        SA_PROJECT_ID="$SHARED_NETWORK_PROJECT"
    fi
fi

KEY_FILE="github-actions-key.json"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."

    command -v gcloud >/dev/null 2>&1 || { log_error "gcloud CLI is required but not installed."; exit 1; }

    if [[ -z "$ORG_ID" ]]; then
        log_error "ORG_ID environment variable is required"
        exit 1
    fi

    if [[ -z "$PROJECT_PREFIX" ]]; then
        log_error "PROJECT_PREFIX environment variable is required"
        exit 1
    fi

    if [[ -z "$VERSION_SUFFIX" ]]; then
        log_error "VERSION_SUFFIX environment variable is required"
        exit 1
    fi

    # Check if user is authenticated
    if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
        log_error "No active gcloud authentication found. Please run 'gcloud auth login'"
        exit 1
    fi

    # Check if shared network project exists
    if ! gcloud projects describe "$SHARED_NETWORK_PROJECT" >/dev/null 2>&1; then
        log_error "Shared network project '$SHARED_NETWORK_PROJECT' does not exist"
        log_error "Please run './scripts/setup.sh' first to create the infrastructure projects"
        exit 1
    fi

    log_info "Prerequisites check passed"
}

# Create or update service account
setup_service_account() {
    log_step "Setting up GitHub Actions service account..."

    # Check if service account already exists
    if gcloud iam service-accounts describe "$SA_EMAIL" --project="$SA_PROJECT_ID" >/dev/null 2>&1; then
        log_info "Service account $SA_EMAIL already exists"
    else
        log_info "Creating service account $SA_EMAIL in project $SA_PROJECT_ID"
        gcloud iam service-accounts create "$SA_NAME" \
            --project="$SA_PROJECT_ID" \
            --display-name="GitHub Actions" \
            --description="Service account for GitHub Actions CI/CD"
    fi

    log_info "Service account setup complete"
}

# Grant permissions on shared network project
grant_shared_network_permissions() {
    log_step "Granting permissions on shared network project..."

    local roles=(
        "roles/owner"
        "roles/storage.admin"
    )

    for role in "${roles[@]}"; do
        log_info "Granting $role to service account on $SHARED_NETWORK_PROJECT"
        gcloud projects add-iam-policy-binding "$SHARED_NETWORK_PROJECT" \
            --member="serviceAccount:$SA_EMAIL" \
            --role="$role" \
            --quiet
    done

    log_info "Shared network project permissions granted"
}

# Grant organization-level permissions
grant_organization_permissions() {
    log_step "Granting organization-level permissions..."

    if [[ -n "$FOLDER_ID" && "$FOLDER_ID" != "" ]]; then
        log_info "Using folder: $FOLDER_ID"

        # Grant project creator role on folder
        log_info "Granting roles/resourcemanager.projectCreator to service account on folder $FOLDER_ID"
        gcloud resource-manager folders add-iam-policy-binding "$FOLDER_ID" \
            --member="serviceAccount:$SA_EMAIL" \
            --role="roles/resourcemanager.projectCreator" \
            --quiet

        # Grant billing user role on organization (required even with folders)
        log_info "Granting roles/billing.user to service account on organization $ORG_ID"
        gcloud organizations add-iam-policy-binding "$ORG_ID" \
            --member="serviceAccount:$SA_EMAIL" \
            --role="roles/billing.user" \
            --quiet
    else
        log_info "Using organization: $ORG_ID"

        # Grant both roles on organization
        local org_roles=(
            "roles/resourcemanager.projectCreator"
            "roles/billing.user"
        )

        for role in "${org_roles[@]}"; do
            log_info "Granting $role to service account on organization $ORG_ID"
            gcloud organizations add-iam-policy-binding "$ORG_ID" \
                --member="serviceAccount:$SA_EMAIL" \
                --role="$role" \
                --quiet
        done
    fi

    log_info "Organization permissions granted"
}

# Generate or update service account key
generate_key() {
    log_step "Generating service account key..."

    if [[ -f "$KEY_FILE" ]]; then
        log_warn "Key file $KEY_FILE already exists"
        read -p "Do you want to generate a new key? This will invalidate the existing key. (y/N): " -r
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Skipping key generation"
            return
        fi
        log_info "Generating new key (old key will be invalidated)"
    fi

    gcloud iam service-accounts keys create "$KEY_FILE" \
        --iam-account="$SA_EMAIL" \
        --project="$SA_PROJECT_ID"

    # Set secure permissions on key file
    chmod 600 "$KEY_FILE"

    log_info "Service account key generated: $KEY_FILE"
}

# Verify permissions
verify_permissions() {
    log_step "Verifying service account permissions..."

    # Test storage access on shared network project
    log_info "Testing storage access..."
    if gcloud projects get-iam-policy "$SHARED_NETWORK_PROJECT" \
        --filter="bindings.members:serviceAccount:$SA_EMAIL" \
        --format="value(bindings.role)" | grep -q "storage.admin\|owner"; then
        log_info "✓ Storage access verified"
    else
        log_warn "✗ Storage access not found"
    fi

    # Test project creation permissions
    log_info "Testing project creation permissions..."
    if [[ -n "$FOLDER_ID" && "$FOLDER_ID" != "" ]]; then
        if gcloud resource-manager folders get-iam-policy "$FOLDER_ID" \
            --filter="bindings.members:serviceAccount:$SA_EMAIL" \
            --format="value(bindings.role)" | grep -q "resourcemanager.projectCreator"; then
            log_info "✓ Project creation access verified"
        else
            log_warn "✗ Project creation access not found"
        fi
    else
        if gcloud organizations get-iam-policy "$ORG_ID" \
            --filter="bindings.members:serviceAccount:$SA_EMAIL" \
            --format="value(bindings.role)" | grep -q "resourcemanager.projectCreator"; then
            log_info "✓ Project creation access verified"
        else
            log_warn "✗ Project creation access not found"
        fi
    fi

    log_info "Permission verification complete"
}

# Display next steps
show_next_steps() {
    log_step "Setup complete! Next steps:"
    echo ""
    echo "1. Add the service account key to GitHub secrets:"
    echo "   - Go to your GitHub repository settings"
    echo "   - Navigate to Secrets and variables > Actions"
    echo "   - Add a new repository secret:"
    echo "     Name: GCP_SA_KEY"
    echo "     Value: Copy the entire contents of $KEY_FILE"
    echo ""
    echo "2. Add other required GitHub secrets:"
    echo "   - GCP_ORG_ID: $ORG_ID"
    echo "   - GCP_PROJECT_ID: $SHARED_NETWORK_PROJECT"
    if [[ -n "$FOLDER_ID" && "$FOLDER_ID" != "" ]]; then
        echo "   - GCP_FOLDER_ID: $FOLDER_ID"
    fi
    echo ""
    echo "3. The service account email is: $SA_EMAIL"
    echo ""
    echo "4. Key file location: $KEY_FILE"
    echo "   ⚠️  Keep this file secure and do not commit it to version control!"
    echo ""
    echo "5. Test your GitHub Actions workflows"
}

# Main execution
main() {
    log_info "Starting GitHub Actions service account setup..."
    echo "Configuration:"
    echo "  Project Prefix: $PROJECT_PREFIX"
    echo "  Version Suffix: $VERSION_SUFFIX"
    echo "  Shared Network Project: $SHARED_NETWORK_PROJECT"
    echo "  Service Account Project: $SA_PROJECT_ID"
    echo "  Organization ID: $ORG_ID"
    if [[ -n "$FOLDER_ID" && "$FOLDER_ID" != "" ]]; then
        echo "  Folder ID: $FOLDER_ID"
    fi
    echo "  Service Account: $SA_EMAIL"
    echo ""

    check_prerequisites
    setup_service_account
    grant_shared_network_permissions
    grant_organization_permissions
    generate_key
    verify_permissions
    show_next_steps

    log_info "GitHub Actions service account setup completed successfully!"
}

# Handle script arguments
case "${1:-}" in
    --help|-h)
        echo "Usage: $0 [options]"
        echo ""
        echo "Environment variables:"
        echo "  PROJECT_PREFIX    Project prefix (required)"
        echo "  VERSION_SUFFIX    Version suffix (required)"
        echo "  ORG_ID           GCP Organization ID (required)"
        echo "  FOLDER_ID        GCP Folder ID (optional)"
        echo "  SA_PROJECT       Project for service account (optional, defaults to gcloud default project)"
        echo ""
        echo "Examples:"
        echo "  # Use default project for service account"
        echo "  ORG_ID=YOUR_ORG_ID $0"
        echo ""
        echo "  # Specify service account project explicitly"
        echo "  ORG_ID=YOUR_ORG_ID SA_PROJECT=YOUR_SA_PROJECT $0"
        exit 0
        ;;
    *)
        main "$@"
        ;;
esac
