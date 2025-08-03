# Configuration Guide

This document explains how to configure the URL Shortener infrastructure with explicit variable management.

## Philosophy

All Terraform variables **must be explicitly set** - no default values are provided. This ensures:

- **Intentional Configuration**: Every value is consciously chosen
- **Environment Clarity**: No hidden defaults that might cause confusion
- **Enterprise Compliance**: Explicit configuration is required for production systems
- **Security**: Sensitive values are never committed to source control

## Required Environment Variables

These variables **must** be set via `TF_VAR_` environment variables:

```bash
# GCP Organization and Billing (Required)
export TF_VAR_organization_id="123456789012"
export TF_VAR_billing_account="012345-678901-234567"

# Domain Configuration (Required)
export TF_VAR_domain_name="go.r19s.net"

# GCP Folder (Optional - set to empty string if not using folders)
export TF_VAR_folder_id=""  # or "123456789" if using folders
```

## Configuration Files

All other variables are explicitly set in `terraform.tfvars` files:

### Development Environment (`infra/environments/dev/terraform.tfvars`)
```hcl
environment = "dev"
project_prefix = "urlshort"
region = "europe-west1"
zones = ["europe-west1-b", "europe-west1-c", "europe-west1-d"]
enable_autopilot = true
enable_istio = true
node_count = 1
machine_type = "e2-standard-2"
```

### Production Environment (`infra/environments/prod/terraform.tfvars`)
```hcl
environment = "prod"
project_prefix = "urlshort"
region = "europe-west1"
zones = ["europe-west1-b", "europe-west1-c", "europe-west1-d"]
enable_autopilot = true
enable_istio = true
node_count = 3
machine_type = "e2-standard-4"
```

## Setup Process

1. **Copy Environment Template**:
   ```bash
   cp .env.example .env
   ```

2. **Edit Configuration**:
   ```bash
   vim .env  # Set your actual values
   ```

3. **Source Environment**:
   ```bash
   source .env
   ```

4. **Validate Configuration**:
   ```bash
   make check-env
   ```

5. **Deploy**:
   ```bash
   make plan-dev    # Review changes
   make apply-dev   # Apply infrastructure
   ```

## Variable Reference

### Required via TF_VAR_
| Variable | Description | Example |
|----------|-------------|---------|
| `TF_VAR_organization_id` | GCP Organization ID | `123456789012` |
| `TF_VAR_billing_account` | Billing Account ID | `012345-678901-234567` |
| `TF_VAR_domain_name` | Base domain name | `go.r19s.net` |
| `TF_VAR_folder_id` | GCP Folder ID (optional) | `""` or `123456789` |

### Set in terraform.tfvars
| Variable | Description | Dev Value | Prod Value |
|----------|-------------|-----------|------------|
| `environment` | Environment name | `dev` | `prod` |
| `project_prefix` | Project name prefix | `urlshort` | `urlshort` |
| `region` | GCP region | `europe-west1` | `europe-west1` |
| `zones` | Availability zones | `[...]` | `[...]` |
| `enable_autopilot` | Use GKE Autopilot | `true` | `true` |
| `enable_istio` | Enable Istio mesh | `true` | `true` |
| `node_count` | Nodes per zone | `1` | `3` |
| `machine_type` | Node machine type | `e2-standard-2` | `e2-standard-4` |

## Domain Configuration

The domain configuration is handled automatically:

- **Development**: `dev.${TF_VAR_domain_name}` (e.g., `dev.go.r19s.net`)
- **Production**: `${TF_VAR_domain_name}` (e.g., `go.r19s.net`)

This is configured in the environment-specific scripts:
- `scripts/env-dev.sh` - Adds `dev.` prefix
- `scripts/env-prod.sh` - Uses domain as-is

## Validation

The `make check-env` command validates that all required environment variables are set:

```bash
$ make check-env
✅ Required environment variables are set
ℹ️  Optional: Set TF_VAR_folder_id if using GCP folders
```

If any required variables are missing:

```bash
$ make check-env
ERROR: TF_VAR_organization_id is not set
Please set: export TF_VAR_organization_id='your-org-id'
```

## CI/CD Integration

For automated deployments, set environment variables in your CI/CD system:

### GitHub Actions
```yaml
env:
  TF_VAR_organization_id: ${{ secrets.GCP_ORG_ID }}
  TF_VAR_billing_account: ${{ secrets.GCP_BILLING_ACCOUNT }}
  TF_VAR_domain_name: ${{ secrets.DOMAIN_NAME }}
  TF_VAR_folder_id: ${{ secrets.GCP_FOLDER_ID }}
```

### Cloud Build
```yaml
substitutions:
  _ORGANIZATION_ID: '123456789012'
  _BILLING_ACCOUNT: '012345-678901-234567'
  _DOMAIN_NAME: 'go.r19s.net'
  _FOLDER_ID: ''
```

## Best Practices

1. **Never commit .env files** - They're in `.gitignore` for a reason
2. **Use .env.example as template** - Keep it updated with required variables
3. **Validate before deployment** - Always run `make check-env` first
4. **Environment separation** - Use different values per environment
5. **Secure storage** - Store sensitive values in secure secret management systems

## Troubleshooting

### Variable Not Set Error
```
ERROR: TF_VAR_organization_id is not set
```
**Solution**: Export the missing variable or source your `.env` file.

### Empty Folder ID
If not using GCP folders, set `TF_VAR_folder_id=""` (empty string).

### Domain Issues
Ensure `TF_VAR_domain_name` is set without protocol (no `https://`) and without subdomain prefixes.