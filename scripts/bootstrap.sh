#!/bin/bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

    # Check if user is authenticated
    if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
        log_error "No active gcloud authentication found. Please run 'gcloud auth login'"
        exit 1
    fi

    log_info "Prerequisites check passed"
}

# enable all Google APIs required for the project
enable_google_apis() {
    log_step "Enabling Google APIs..."
    gcloud services enable \
        storage.googleapis.com \
        cloudresourcemanager.googleapis.com \
        serviceusage.googleapis.com \
        iam.googleapis.com \
        pubsub.googleapis.com \
        monitoring.googleapis.com \
        logging.googleapis.com \
        servicemanagement.googleapis.com
}


# Main execution
main() {
    log_info "Starting bootstrapping environment setup..."

    check_prerequisites
    enable_google_apis

    log_info "GitHub Actions service account setup completed successfully!"
}

main "$@"
