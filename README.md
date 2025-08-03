# Enterprise URL Shortener on GCP

Small URLs, huge cloud bill - but with enterprise-grade architecture! 🚀

This project demonstrates a production-ready URL shortener service deployed on Google Cloud Platform (GCP) using enterprise patterns including:

- **Landing Zone Architecture** with project factory pattern
- **GKE with Istio** service mesh for advanced traffic management
- **Multi-environment setup** (dev/prod) with proper separation
- **Infrastructure as Code** using Terraform
- **Security best practices** with Binary Authorization, mTLS, and RBAC
- **Comprehensive monitoring** and alerting
- **CI/CD pipelines** with GitHub Actions

## Architecture Overview

```
Organization
├── envs/
│   ├── dev/
│   │   ├── dev-app        ← GKE, service workloads
│   │   └── dev-ci         ← Build pipelines
│   └── prod/
│       ├── prod-app       ← GKE, service workloads
│       └── prod-ci        ← Build pipelines
├── shared/
│   ├── shared-network     ← Shared VPC, Cloud NAT
│   ├── security           ← SCC, policies, audit config
│   └── logging-monitoring ← Central logs and metrics
```

## Technology Stack

- **Cloud Platform**: Google Cloud Platform (GCP)
- **Container Orchestration**: Google Kubernetes Engine (GKE) with Autopilot
- **Service Mesh**: Istio for traffic management, security, and observability
- **Infrastructure**: Terraform with modular design
- **CI/CD**: GitHub Actions with comprehensive security scanning
- **Monitoring**: Cloud Operations Suite with custom dashboards
- **Security**: Cloud Security Command Center, KMS, Secret Manager
- **Networking**: Shared VPC with Cloud NAT

## Project Structure

```
.
├── infra/                          # Terraform infrastructure
│   ├── modules/                    # Reusable Terraform modules
│   │   ├── project-factory/        # GCP project creation
│   │   ├── shared-vpc/             # Shared VPC networking
│   │   ├── gke/                    # GKE cluster configuration
│   │   ├── security/               # Security configurations
│   │   └── logging-monitoring/     # Logging and monitoring
│   ├── environments/               # Environment-specific configs
│   │   ├── dev/                   # Development environment
│   │   └── prod/                  # Production environment
│   └── *.tf                      # Main Terraform files
├── k8s/                           # Kubernetes manifests
│   ├── istio/                     # Istio configurations
│   ├── monitoring/                # Monitoring configs
│   └── *.yaml                     # Application manifests
├── scripts/                       # Setup and utility scripts
├── .github/workflows/            # GitHub Actions CI/CD
├── Dockerfile                    # Container image
├── Makefile                      # Deployment automation
└── README.md                     # This file
```

## Prerequisites

1. **GCP Organization** with billing account
2. **IAM Permissions**:
   - Organization Admin (for initial setup)
   - Project Creator
   - Billing Account User
   - Security Admin
3. **Local Tools**:
   - [Google Cloud SDK](https://cloud.google.com/sdk/docs/install)
   - [Terraform](https://developer.hashicorp.com/terraform/downloads) >= 1.0
   - [kubectl](https://kubernetes.io/docs/tasks/tools/)
   - Docker (for local development)

## Quick Start

### 1. Initial Setup

```bash
# Clone the repository
git clone <repository-url>
cd url-shortener

# Set up environment
cp .env.example .env
# Edit .env with your actual GCP values

# Source environment variables
source .env

# Run setup script
chmod +x scripts/setup.sh
./scripts/setup.sh
```

### 2. Configure GitHub Secrets

Set up repository secrets for GitHub Actions:

```bash
# Required secrets in GitHub repository settings:
GCP_ORG_ID              # Your GCP Organization ID
GCP_BILLING_ACCOUNT     # Your Billing Account ID
DOMAIN_NAME             # Your domain (e.g., go.r19s.net)
GCP_FOLDER_ID           # GCP Folder ID (optional, can be empty)
GCP_SA_KEY              # Service Account JSON key
GCP_PROJECT_ID          # Default project for gcloud commands
```

### 3. Deploy Infrastructure

**Using GitHub Actions (Recommended):**
```bash
# Push to main branch - automatically deploys to dev
git add .
git commit -m "Initial infrastructure setup"
git push origin main

# For production: Use GitHub UI workflow dispatch
# Go to Actions → Deploy Production Infrastructure → Run workflow
```

**Using Local Make Commands:**
```bash
# Local deployment (requires gcloud setup)
make plan-dev    # Review the plan
make apply-dev   # Apply changes
```

### 4. Deploy Application

```bash
# Get cluster credentials
make get-credentials-dev

# Deploy to development
kubectl apply -f k8s/

# Check deployment status
make status
```

## Key Features

### 🏗️ Enterprise Architecture
- Project factory pattern for consistent project creation
- Shared VPC for centralized network management
- Multi-environment separation with proper RBAC

### 🔒 Security First
- mTLS between all services via Istio
- Binary Authorization for container image security
- Cloud KMS for encryption key management
- Secret Manager for sensitive data
- Security Command Center for threat detection

### 📊 Observability
- Comprehensive logging with Cloud Logging
- Custom metrics and dashboards
- Distributed tracing with Cloud Trace
- Uptime monitoring and alerting
- Performance analytics with BigQuery

### 🚀 Scalability & Reliability
- GKE Autopilot for automatic scaling
- Horizontal Pod Autoscaler with custom metrics
- Istio traffic management and circuit breakers
- Multi-zone deployment for high availability

### 🔄 CI/CD Integration
- **GitHub Actions workflows** for infrastructure and applications
- **Comprehensive security scanning** (Terraform, containers, dependencies)
- **Environment protection** with manual approvals for production
- **Automated dev deployment** with manual production promotion

## Configuration

### Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `ORG_ID` | GCP Organization ID | Yes |
| `BILLING_ACCOUNT` | Billing Account ID | Yes |
| `PROJECT_PREFIX` | Prefix for project names | No |
| `REGION` | Primary GCP region | No |

### Configuration Approach

This infrastructure uses **explicit configuration** - no default values are provided. All variables must be intentionally set:

**Required Environment Variables** (via `TF_VAR_`):
```bash
export TF_VAR_organization_id="123456789012"
export TF_VAR_billing_account="012345-678901-234567"
export TF_VAR_domain_name="go.r19s.net"
export TF_VAR_folder_id=""  # Empty if not using folders
```

**Explicit terraform.tfvars Configuration**:
```hcl
environment = "dev"  # or "prod"
project_prefix = "urlshort"
region = "europe-west1"
zones = ["europe-west1-b", "europe-west1-c", "europe-west1-d"]
enable_istio = true
enable_autopilot = true
node_count = 1  # dev: 1, prod: 3
machine_type = "e2-standard-2"  # dev: e2-standard-2, prod: e2-standard-4
```

## Security Considerations

### Network Security
- Private GKE cluster with authorized networks
- Shared VPC with controlled subnet access
- Cloud NAT for outbound internet access
- Firewall rules following least privilege

### Application Security
- Non-root container execution
- Read-only root filesystem
- Security contexts and Pod Security Standards
- Resource limits and requests

### Data Security
- Encryption at rest with Cloud KMS
- Secrets stored in Secret Manager
- mTLS for service-to-service communication
- Regular vulnerability scanning

## Monitoring & Alerting

### Default Alerts
- High error rate (>5%)
- High latency (>1000ms)
- Pod crash loops
- Security events

### Dashboards
- Application performance metrics
- Infrastructure health
- Security overview
- Cost optimization

### Custom Metrics
- URL shortener request rate
- Request latency percentiles
- Cache hit ratios
- Business metrics

## Operations

### Common Commands

```bash
# Infrastructure
make plan-dev          # Plan development changes
make apply-dev         # Apply development changes
make destroy-dev       # Destroy development environment

# Application
make build            # Build Docker image
make deploy-dev       # Deploy to development
make logs             # View application logs
make port-forward     # Port forward for local access

# Monitoring
make status           # Check deployment status
kubectl get pods -n url-shortener
kubectl logs -f deployment/url-shortener -n url-shortener
```

### Troubleshooting

1. **Terraform Issues**:
   ```bash
   make validate         # Validate configuration
   make lint            # Lint Terraform files
   terraform refresh    # Refresh state
   ```

2. **GKE Issues**:
   ```bash
   kubectl describe pods -n url-shortener
   kubectl get events -n url-shortener
   kubectl logs -f deployment/url-shortener -n url-shortener
   ```

3. **Istio Issues**:
   ```bash
   istioctl proxy-status
   istioctl analyze
   kubectl logs -f deployment/istiod -n istio-system
   ```

## Cost Optimization

### Development Environment
- Uses smaller machine types
- Single replica deployments
- Shared resources where possible

### Production Environment
- Auto-scaling based on demand
- Preemptible nodes for non-critical workloads
- Resource requests optimized for efficiency

### Monitoring
- BigQuery analytics for cost attribution
- Custom alerts for budget thresholds
- Regular cost optimization reviews

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make changes and test thoroughly
4. Submit a pull request with detailed description

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For questions or issues:

1. Check the troubleshooting section
2. Review GCP documentation
3. Open an issue with detailed information
4. Consult the Terraform and Kubernetes documentation

---

**Note**: This is a demonstration project for showcasing enterprise-grade cloud architecture patterns. Ensure you review and customize all configurations for your specific security and compliance requirements before using in production.