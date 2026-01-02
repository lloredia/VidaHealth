.PHONY: help build run test staging-init staging-plan staging-apply prod-init prod-plan prod-apply clean

help:
	@echo "Available targets:"
	@echo "  build          - Build Docker image locally"
	@echo "  run            - Run Docker container locally"
	@echo "  test           - Test local Docker container"
	@echo "  staging-init   - Initialize Terraform for staging"
	@echo "  staging-plan   - Plan Terraform changes for staging"
	@echo "  staging-apply  - Apply Terraform changes for staging"
	@echo "  prod-init      - Initialize Terraform for production"
	@echo "  prod-plan      - Plan Terraform changes for production"
	@echo "  prod-apply     - Apply Terraform changes for production"
	@echo "  clean          - Clean up local resources"

build:
	docker build -t vida-interview:local \
		--build-arg GIT_COMMIT_SHA=$$(git rev-parse --short HEAD) \
		--build-arg SERVICE_NAME=vida-interview \
		.

run: build
	docker run --rm -p 8080:8080 \
		-e SERVICE_NAME=vida-interview \
		-e APP_ENV=local \
		-e GIT_COMMIT_SHA=$$(git rev-parse --short HEAD) \
		vida-interview:local

test: build
	@echo "Starting test container..."
	@docker run -d --name vida-test \
		-p 8080:8080 \
		-e SERVICE_NAME=vida-interview \
		-e APP_ENV=test \
		-e GIT_COMMIT_SHA=$$(git rev-parse --short HEAD) \
		vida-interview:local
	@sleep 3
	@echo "Testing endpoint..."
	@curl -s http://localhost:8080/ | jq .
	@docker stop vida-test
	@docker rm vida-test
	@echo "Test passed!"

staging-init:
	cd terraform/environments/staging && terraform init

staging-plan: staging-init
	cd terraform/environments/staging && terraform plan

staging-apply: staging-init
	cd terraform/environments/staging && terraform apply

prod-init:
	cd terraform/environments/production && terraform init

prod-plan: prod-init
	cd terraform/environments/production && terraform plan

prod-apply: prod-init
	cd terraform/environments/production && terraform apply

clean:
	docker rmi vida-interview:local || true
	docker rm -f vida-test || true
	cd terraform/environments/staging && rm -rf .terraform terraform.tfstate* || true
	cd terraform/environments/production && rm -rf .terraform terraform.tfstate* || true
