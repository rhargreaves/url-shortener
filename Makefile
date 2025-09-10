ifeq ($(TERRAFORM_PROJECT_ID),)
$(error TERRAFORM_PROJECT_ID is not set)
endif
ifeq ($(TERRAFORM_BUCKET_PREFIX),)
$(error TERRAFORM_BUCKET_PREFIX is not set)
endif

init:
	@echo "Creating Terraform state buckets..."
	gsutil mb -p $(TERRAFORM_PROJECT_ID) gs://$(TERRAFORM_BUCKET_PREFIX)-terraform-state-dev || true
	gsutil mb -p $(TERRAFORM_PROJECT_ID) gs://$(TERRAFORM_BUCKET_PREFIX)-terraform-state-prod || true
	gsutil mb -p $(TERRAFORM_PROJECT_ID) gs://$(TERRAFORM_BUCKET_PREFIX)-terraform-state-shared || true
	gsutil versioning set on gs://$(TERRAFORM_BUCKET_PREFIX)-terraform-state-dev
	gsutil versioning set on gs://$(TERRAFORM_BUCKET_PREFIX)-terraform-state-prod
	gsutil versioning set on gs://$(TERRAFORM_BUCKET_PREFIX)-terraform-state-shared
	@echo "Initializing Terraform..."
	cd infra && terraform init
	cd infra/environments/shared && terraform init -upgrade \
			-backend-config="bucket=$(TERRAFORM_BUCKET_PREFIX)-terraform-state-shared" \
			-backend-config="prefix=shared/terraform.tfstate"
	cd infra/environments/dev && terraform init -upgrade \
		-backend-config="bucket=$(TERRAFORM_BUCKET_PREFIX)-terraform-state-dev" \
		-backend-config="prefix=dev/terraform.tfstate"
	cd infra/environments/prod && terraform init -upgrade \
		-backend-config="bucket=$(TERRAFORM_BUCKET_PREFIX)-terraform-state-prod" \
		-backend-config="prefix=prod/terraform.tfstate"
.PHONY: init

# Check required environment variables
.PHONY: check-env
check-env:
	@if [ -z "$$TF_VAR_organization_id" ]; then \
		echo "ERROR: TF_VAR_organization_id is not set"; \
		echo "Please set: export TF_VAR_organization_id='your-org-id'"; \
		exit 1; \
	fi
	@if [ -z "$$TF_VAR_billing_account" ]; then \
		echo "ERROR: TF_VAR_billing_account is not set"; \
		echo "Please set: export TF_VAR_billing_account='your-billing-account'"; \
		exit 1; \
	fi
	@if [ -z "$$TF_VAR_domain_name" ]; then \
		echo "ERROR: TF_VAR_domain_name is not set"; \
		echo "Please set: export TF_VAR_domain_name='your-domain.com'"; \
		exit 1; \
	fi
	@echo "✅ Required environment variables are set"
	@echo "ℹ️  Optional: Set TF_VAR_folder_id if using GCP folders"

# Shared environment
.PHONY: plan-shared
plan-shared: check-env
	@echo "🔧 Configuring shared environment..."
	@source scripts/env-shared.sh && cd infra/environments/shared && terraform plan -var-file=terraform.tfvars -out=tfplan

.PHONY: apply-shared
apply-shared: check-env
	@echo "🔧 Configuring shared environment..."
	@source scripts/env-shared.sh && cd infra/environments/shared && terraform apply -var-file=terraform.tfvars -auto-approve tfplan

.PHONY: destroy-shared
destroy-shared:
	cd infra/environments/shared && terraform destroy -var-file=terraform.tfvars -auto-approve

# Development environment
.PHONY: plan-dev
plan-dev: check-env
	@echo "🔧 Configuring development environment..."
	@source scripts/env-dev.sh && cd infra/environments/dev && terraform plan -var-file=terraform.tfvars

.PHONY: apply-dev
apply-dev: check-env
	@echo "🔧 Configuring development environment..."
	@source scripts/env-dev.sh && cd infra/environments/dev && terraform apply -var-file=terraform.tfvars -auto-approve

.PHONY: destroy-dev
destroy-dev:
	cd infra/environments/dev && terraform destroy -var-file=terraform.tfvars -auto-approve

# Production environment
.PHONY: plan-prod
plan-prod: check-env
	@echo "🚀 Configuring production environment..."
	@source scripts/env-prod.sh && cd infra/environments/prod && terraform plan -var-file=terraform.tfvars

.PHONY: apply-prod
apply-prod: check-env
	@echo "🚀 Configuring production environment..."
	@source scripts/env-prod.sh && cd infra/environments/prod && terraform apply -var-file=terraform.tfvars -auto-approve

.PHONY: destroy-prod
destroy-prod:
	cd infra/environments/prod && terraform destroy -var-file=terraform.tfvars -auto-approve

# Build and deploy
.PHONY: build
build:
	docker build -t gcr.io/$(PROJECT_PREFIX)-dev-app/url-shortener:latest .

.PHONY: deploy-dev
deploy-dev: build
	docker push gcr.io/$(PROJECT_PREFIX)-dev-app/url-shortener:latest
	kubectl apply -f k8s/ --context=$(PROJECT_PREFIX)-dev-app

.PHONY: deploy-prod
deploy-prod: build
	docker push gcr.io/$(PROJECT_PREFIX)-prod-app/url-shortener:latest
	kubectl apply -f k8s/ --context=$(PROJECT_PREFIX)-prod-app

# Linting and validation
.PHONY: lint
lint:
	terraform fmt -recursive infra/
	tflint infra/

.PHONY: validate
validate:
	cd infra && terraform validate
	cd infra/environments/dev && terraform validate
	cd infra/environments/prod && terraform validate

# Cleanup
.PHONY: clean
clean:
	find . -name ".terraform" -type d -exec rm -rf {} + 2>/dev/null || true
	find . -name "terraform.tfstate*" -type f -delete 2>/dev/null || true
	find . -name ".terraform.lock.hcl" -type f -delete 2>/dev/null || true

# Get cluster credentials
.PHONY: get-credentials-dev
get-credentials-dev:
	gcloud container clusters get-credentials dev-url-shortener --region=$(REGION) --project=$(PROJECT_PREFIX)-dev-app

.PHONY: get-credentials-prod
get-credentials-prod:
	gcloud container clusters get-credentials prod-url-shortener --region=$(REGION) --project=$(PROJECT_PREFIX)-prod-app

# Port forward for local development
.PHONY: port-forward
port-forward:
	kubectl port-forward svc/url-shortener 8080:80 -n url-shortener

# View logs
.PHONY: logs
logs:
	kubectl logs -f deployment/url-shortener -n url-shortener

# Status check
.PHONY: status
status:
	kubectl get pods,svc,ingress -n url-shortener
	kubectl get pods,svc -n istio-system

# Security scanning (local)
.PHONY: security-scan
security-scan:
	@echo "Running local security scans..."
	@command -v checkov >/dev/null 2>&1 || { echo "Install checkov: pip install checkov"; exit 1; }
	@command -v hadolint >/dev/null 2>&1 || { echo "Install hadolint: brew install hadolint"; exit 1; }
	checkov -d infra/ --framework terraform
	hadolint Dockerfile
