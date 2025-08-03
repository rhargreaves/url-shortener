# GitHub Actions CI/CD

This document explains the GitHub Actions workflows for the URL Shortener infrastructure.

## Overview

The project uses GitHub Actions instead of Cloud Build for CI/CD, providing:

- **Git-native workflows** with tight GitHub integration
- **Environment protection** with approval gates
- **Comprehensive security scanning** built into the pipeline
- **Explicit configuration** using the TF_VAR_ approach
- **Multi-environment deployment** with automatic dev and manual prod

## Workflows

### 1. Terraform Development (`terraform-dev.yml`)

**Triggers:**
- Push to `main` (infra changes)
- Pull requests (infra changes)
- Manual dispatch

**Features:**
- Automatic deployment to development on main branch
- Plan-only on pull requests with GitHub comments
- Format validation and security checks
- Outputs saved as artifacts

**Environment Variables:**
```yaml
env:
  TF_VAR_organization_id: ${{ secrets.GCP_ORG_ID }}
  TF_VAR_billing_account: ${{ secrets.GCP_BILLING_ACCOUNT }}
  TF_VAR_domain_name: ${{ secrets.DOMAIN_NAME }}
  TF_VAR_folder_id: ${{ secrets.GCP_FOLDER_ID }}
```

### 2. Terraform Production (`terraform-prod.yml`)

**Triggers:**
- After successful dev deployment
- Manual dispatch only for apply/destroy

**Features:**
- **Manual approval required** for production changes
- Runs only after dev workflow succeeds
- Plan generation for review
- Destroy capability via manual dispatch

**Safety Features:**
```yaml
# Only run if dev workflow succeeded
if: github.event.workflow_run.conclusion == 'success'

# Manual approval for apply
if: github.event_name == 'workflow_dispatch' && github.event.inputs.action == 'apply'
```

### 3. Build and Deploy (`build-deploy.yml`)

**Triggers:**
- Application code changes
- Kubernetes manifest changes
- Manual dispatch

**Features:**
- Multi-stage Docker builds
- Container security scanning
- Automatic dev deployment
- Manual production approval
- Image promotion to production registry

**Deployment Flow:**
```
Build → Security Scan → Deploy Dev → Manual Approval → Deploy Prod
```

### 4. Security Scanning (`security-scan.yml`)

**Triggers:**
- All pushes and PRs
- Daily scheduled scans
- Manual dispatch

**Security Tools:**
- **Checkov**: Terraform security analysis
- **TruffleHog**: Secrets detection
- **Hadolint**: Dockerfile security
- **Kubesec**: Kubernetes security
- **Trivy**: Dependency vulnerabilities
- **Polaris**: Kubernetes best practices

## Required Secrets

Configure these secrets in your GitHub repository:

### Organization/Repository Secrets
```bash
GCP_ORG_ID              # GCP Organization ID
GCP_BILLING_ACCOUNT     # Billing Account ID
DOMAIN_NAME             # Base domain (e.g., go.r19s.net)
GCP_FOLDER_ID           # GCP Folder ID (optional, can be empty)
GCP_SA_KEY              # Service Account JSON key
GCP_PROJECT_ID          # Default project ID for gcloud commands
```

### Environment-Specific Secrets
Create environments in GitHub: `development` and `production`

Both environments should have access to the same secrets, but production should have:
- **Protection rules** requiring approvals
- **Branch restrictions** to main only
- **Required reviewers** from security/platform teams

## Service Account Setup

Create a service account with these roles:

```bash
# Create service account
gcloud iam service-accounts create github-actions \
    --display-name="GitHub Actions" \
    --description="Service account for GitHub Actions CI/CD"

# Grant necessary roles
gcloud projects add-iam-policy-binding PROJECT_ID \
    --member="serviceAccount:github-actions@PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/owner"

# Generate key
gcloud iam service-accounts keys create github-actions-key.json \
    --iam-account=github-actions@PROJECT_ID.iam.gserviceaccount.com
```

**Required Roles:**
- Project Creator
- Billing Account User
- Organization Admin (for project creation)
- Container Registry Admin
- GKE Admin
- Security Admin

## Workflow Features

### 1. Environment Protection

**Development:**
- Automatic deployment on main branch
- No approval required
- Fast feedback loop

**Production:**
- Manual approval required
- Plan review before apply
- Protected environment settings

### 2. Security Integration

**SARIF Upload:**
All security tools output to GitHub Security tab:
```yaml
- name: Upload results to GitHub Security
  uses: github/codeql-action/upload-sarif@v3
  with:
    sarif_file: reports/results.sarif
```

**Dependency Management:**
- Dependabot for automatic updates
- Security vulnerability alerts
- Automated dependency PRs

### 3. Pull Request Integration

**Terraform Plans:**
Automatic comments on PRs with Terraform plans:
```
#### Terraform Development Plan 📖

<details><summary>Show Plan</summary>

```terraform
# Plan output here
```

</details>
```

**Security Feedback:**
Security scan results appear as:
- GitHub Security tab alerts
- PR status checks
- Inline code annotations

## Usage Examples

### 1. Deploy Development Infrastructure

```bash
# Commit infrastructure changes
git add infra/
git commit -m "Update GKE configuration"
git push origin main

# Automatically triggers:
# 1. terraform-dev.yml (auto-deploy)
# 2. terraform-prod.yml (plan only)
```

### 2. Deploy to Production

1. **Navigate to Actions tab**
2. **Select "Deploy Production Infrastructure"**
3. **Click "Run workflow"**
4. **Select action: "apply"**
5. **Click "Run workflow"**

### 3. Deploy Application

```bash
# Commit application changes
git add src/ k8s/
git commit -m "Add new feature"
git push origin main

# Automatically triggers:
# 1. Build and test
# 2. Deploy to dev
# 3. Wait for manual prod approval
```

### 4. Emergency Procedures

**Rollback Production:**
```bash
# Use workflow dispatch to deploy previous version
# Or destroy and recreate from known good state
```

**Infrastructure Destroy:**
```bash
# Use workflow dispatch with "destroy" action
# Requires manual confirmation
```

## Monitoring and Alerts

### 1. Workflow Notifications

Configure notifications in GitHub:
- Slack/Teams integration
- Email notifications
- Custom webhooks

### 2. Security Alerts

- **Dependabot alerts** for vulnerable dependencies
- **Security tab** for SARIF results
- **PR status checks** for security failures

### 3. Deployment Status

- **Environment deployment** status on GitHub
- **Artifact storage** for Terraform outputs
- **Deployment history** with rollback capability

## Best Practices

### 1. Secret Management
- Use GitHub secrets for sensitive data
- Rotate service account keys regularly
- Scope service accounts to minimum permissions

### 2. Environment Strategy
- Always deploy to dev first
- Require approval for production
- Use feature flags for application changes

### 3. Security
- Run security scans on every change
- Review SARIF outputs regularly
- Keep dependencies updated with Dependabot

### 4. Monitoring
- Set up deployment notifications
- Monitor workflow execution times
- Track deployment success rates

## Troubleshooting

### Common Issues

**Secret Not Found:**
```
ERROR: GCP_ORG_ID secret not set
```
**Solution:** Check GitHub repository secrets configuration.

**Terraform State Lock:**
```
Error: Error acquiring the state lock
```
**Solution:** Check for concurrent runs, manually unlock if needed.

**GKE Authentication:**
```
ERROR: (gcloud.container.clusters.get-credentials) ResponseError: code=403
```
**Solution:** Verify service account permissions and project ID.

### Debugging Workflows

1. **Check workflow logs** in GitHub Actions tab
2. **Verify secrets** are set correctly
3. **Test locally** with same environment variables
4. **Check service account** permissions
5. **Validate Terraform** configuration locally

## Migration from Cloud Build

✅ **Migration Complete!** The old Cloud Build files have been removed:
- `cloudbuild.yaml` - ❌ Removed
- `cloudbuild-parameterized.yaml` - ❌ Removed

The project now uses GitHub Actions exclusively for CI/CD with:
- Better git integration
- Enhanced security scanning
- Environment protection
- Manual approval workflows