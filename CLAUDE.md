# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a Terraform repository for deploying Dify (AI application development platform) on Google Cloud Platform with a highly available, serverless architecture. The infrastructure includes Cloud Run, Cloud SQL (PostgreSQL with pgvector), Memorystore (Redis), Cloud Storage, Filestore, and VPC networking.

## Common Development Commands

### Terraform Commands
```bash
# Navigate to the environment directory
cd terraform/environments/dev

# Initialize Terraform (required before any other Terraform commands)
terraform init

# Format all Terraform files recursively
terraform fmt -recursive

# Validate Terraform configuration
terraform validate

# Plan infrastructure changes
terraform plan

# Apply infrastructure changes
terraform apply

# Apply specific module only (e.g., registry module)
terraform apply -target=module.registry

# Destroy infrastructure (Note: Some resources require manual deletion)
terraform destroy
```

### Docker Build Commands
```bash
# Build and push container images to Google Artifact Registry
# Usage: sh ./docker/cloudbuild.sh <project-id> <region> [dify-api-version]
sh ./docker/cloudbuild.sh your-project-id us-central1
# Or with specific Dify API version
sh ./docker/cloudbuild.sh your-project-id us-central1 1.0.0
```

### Testing and Validation
- Terraform validation is automatically run on pull requests via GitHub Actions
- Terraform formatting is automatically applied on pull requests
- No unit tests are defined in this repository

## Architecture and Module Structure

### Environment Configuration
- **`terraform/environments/dev/`**: Contains the main Terraform configuration that orchestrates all modules
  - `main.tf`: Defines module usage and enables required Google Cloud APIs
  - `variables.tf`: Defines all configurable variables
  - `terraform.tfvars`: Template file for environment-specific values (never commit with real values)
  - `provider.tf`: Configures Terraform backend state storage in GCS

### Terraform Modules
Each module in `terraform/modules/` is self-contained with its own:
- `main.tf`: Resource definitions
- `variables.tf`: Input variables
- `outputs.tf`: Output values for use by other modules

Key modules:
- **cloudrun**: Deploys Dify API, Web UI, Sandbox, Plugin Daemon, and NGINX containers
- **cloudsql**: PostgreSQL database with pgvector extension for vector storage
- **redis**: Memorystore instance for Celery broker and caching
- **network**: VPC with subnet and service networking for private Google services
- **storage**: Cloud Storage bucket for file uploads
- **filestore**: NFS storage for shared files between containers
- **registry**: Artifact Registry repositories for Docker images

### Module Dependencies
The infrastructure has a specific deployment order:
1. Enable Google Cloud APIs (`google_project_service.enabled_services`)
2. Create network resources (VPC, subnets)
3. Deploy storage resources (Cloud Storage, Filestore)
4. Set up databases (Cloud SQL, Redis)
5. Create Artifact Registry
6. Deploy Cloud Run services

### Security Considerations
- All sensitive values should be in `terraform.tfvars` (which must not be committed)
- Cloud SQL uses private IP only (no public access)
- Redis is only accessible within VPC
- Cloud Run services use VPC connector for private resource access
- Service accounts follow least-privilege principle

### Deployment Workflow
1. First deployment requires creating Artifact Registry: `terraform apply -target=module.registry`
2. Build and push Docker images using the cloudbuild.sh script
3. Deploy remaining infrastructure with `terraform apply`

### Important Notes
- Terraform state is stored in Google Cloud Storage (configure bucket in `provider.tf`)
- Some resources (Cloud Storage, Cloud SQL, VPC) have deletion protection and require manual deletion
- The repository supports Dify v1.0.0 and later
- GitHub Actions automatically format Terraform code and validate configurations on PRs