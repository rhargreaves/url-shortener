REQUIRED_VARS := \
	TF_VAR_organization_id \
	TF_VAR_billing_account \
	TF_VAR_domain_name \
	TF_VAR_folder_id \
	TF_VAR_project_prefix \
	TF_VAR_notification_email \
	TF_VAR_iap_users \
	REGION \
	TERRAFORM_PROJECT_ID \
	TERRAFORM_BUCKET_PREFIX

$(foreach var,$(REQUIRED_VARS),\
  $(if $($(var)),,$(error $(var) is not set))\
)

local-init:
	cd infra && terraform init
.PHONY: local-init

init: local-init
	@echo "Creating Terraform state buckets..."
	gsutil mb -p $(TERRAFORM_PROJECT_ID) gs://$(TERRAFORM_BUCKET_PREFIX)-terraform-state-dev || true
	gsutil mb -p $(TERRAFORM_PROJECT_ID) gs://$(TERRAFORM_BUCKET_PREFIX)-terraform-state-prod || true
	gsutil mb -p $(TERRAFORM_PROJECT_ID) gs://$(TERRAFORM_BUCKET_PREFIX)-terraform-state-shared || true
	gsutil versioning set on gs://$(TERRAFORM_BUCKET_PREFIX)-terraform-state-dev
	gsutil versioning set on gs://$(TERRAFORM_BUCKET_PREFIX)-terraform-state-prod
	gsutil versioning set on gs://$(TERRAFORM_BUCKET_PREFIX)-terraform-state-shared
	@echo "Initializing Terraform..."
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

# Shared environment
plan-shared:
	cd infra/environments/shared && terraform plan -var-file=terraform.tfvars -out=tfplan-shared
.PHONY: plan-shared

apply-shared:
	cd infra/environments/shared && terraform apply tfplan-shared
.PHONY: apply-shared

destroy-shared:
	cd infra/environments/shared && terraform destroy -var-file=terraform.tfvars -auto-approve
.PHONY: destroy-shared

# Development environment
plan-dev:
	cd infra/environments/dev && terraform plan -var-file=terraform.tfvars -out=tfplan-dev
.PHONY: plan-dev

apply-dev:
	cd infra/environments/dev && terraform apply tfplan-dev
.PHONY: apply-dev

destroy-dev:
	cd infra/environments/dev && terraform destroy -var-file=terraform.tfvars -auto-approve
.PHONY: destroy-dev

# Production environment
plan-prod:
	cd infra/environments/prod && terraform plan -var-file=terraform.tfvars -out=tfplan-prod
.PHONY: plan-prod

apply-prod:
	cd infra/environments/prod && terraform apply tfplan-prod
.PHONY: apply-prod

destroy-prod:
	cd infra/environments/prod && terraform destroy -var-file=terraform.tfvars -auto-approve
.PHONY: destroy-prod

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
