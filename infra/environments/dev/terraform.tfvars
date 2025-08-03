# Development environment configuration

# Environment specific variables like:
#  organization_id
#  billing_account
#  domain_name
#  folder_id
# should be set via TF_VAR_ environment variables

environment = "dev"

# Project naming
project_prefix = "urlshort"

# Regional configuration
region = "europe-west1"
zones  = ["europe-west1-b", "europe-west1-c", "europe-west1-d"]

# GKE configuration for development
enable_autopilot = true
enable_istio     = true

# Development-specific settings (if using standard GKE)
node_count   = 1
machine_type = "e2-standard-2"  # Smaller instances for dev