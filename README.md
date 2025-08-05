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

1. **Initial Setup** - Run `./scripts/setup.sh` to create GCP projects and infrastructure
2. **Configure GitHub Actions** - Run `./scripts/setup-github-actions-sa.sh` and add the generated service account key to GitHub secrets
3. **Deploy Infrastructure** - Push to main branch for automatic dev deployment, use GitHub Actions workflow dispatch for production
4. **Deploy Application** - Use `kubectl apply -f k8s/` after getting cluster credentials with `make get-credentials-dev`

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

The project uses GitHub Actions for automated CI/CD pipelines that provide infrastructure deployment, application builds, and comprehensive security scanning. The workflows follow enterprise patterns with environment protection and approval gates for production deployments.

**Active Workflows:**
- **Terraform Development** - Automatically deploys infrastructure changes to dev environment on main branch pushes
- **Terraform Production** - Deploys infrastructure to production with manual approval after successful dev deployment
- **Build and Deploy** - Builds container images, performs security scanning, and deploys applications to both environments
- **Security Scanning** - Runs daily security scans using Checkov, TruffleHog, Hadolint, Trivy, and Polaris

**Key Features:**
- Automatic dev deployment with manual production approval
- Comprehensive security scanning integrated into all workflows
- Environment protection with GitHub environments and required reviewers
- Terraform plan outputs posted as PR comments for review

## Configuration

Configuration uses explicit environment variables and terraform.tfvars files. Required variables include GCP organization ID, billing account, domain name, and optional folder ID. Environment-specific settings are defined in `infra/environments/*/terraform.tfvars`.

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

Common operations include `make plan-dev`, `make apply-dev` for infrastructure changes, and `kubectl` commands for application management. Use `make status` to check deployment status and standard Kubernetes/Istio troubleshooting commands as needed.

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
