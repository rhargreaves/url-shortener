# Production environment configuration

# Environment specific variables like:
#  organization_id
#  billing_account
#  domain_name
#  folder_id
# should be set via TF_VAR_ environment variables

environment = "prod"

# Project naming
project_prefix = "rh-urlshort"

# Regional configuration for high availability
region = "europe-west1"
zones  = ["europe-west1-b", "europe-west1-c", "europe-west1-d"]

# GKE configuration for production
enable_autopilot = true
enable_istio     = true
version_suffix   = "v2"

# Production-specific settings (if using standard GKE)
node_count   = 3
machine_type = "e2-standard-2"
