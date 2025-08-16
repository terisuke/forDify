# Repository Operation Guide

This document explains how to operate this repository.

## Remote Repository Configuration

This repository is connected to two remote repositories:

1. **upstream** - Original Repository
   - URL: https://github.com/DeNA/dify-google-cloud-terraform.git
   - Purpose: Obtaining original codebase

2. **origin** - Forked Repository
   - URL: https://github.com/terisuke/forDify.git
   - Purpose: Managing and publishing custom changes

## Basic Commands

### Checking Remotes
```bash
git remote -v
```

### Fetching Latest Code from Upstream
```bash
# Fetch latest information from upstream
git fetch upstream

# Merge upstream changes into local main branch
git merge upstream/main

# Or, if using rebase
git rebase upstream/main
```

### Pushing Changes to Origin
```bash
# Stage changes
git add .

# Commit changes
git commit -m "commit message"

# Push to origin
git push origin main
```

## Development Flow

1. When developing new features or fixing bugs:
   ```bash
   # Create a new branch
   git checkout -b feature/new-feature-name

   # Do development work
   ...

   # Commit changes
   git add .
   git commit -m "Add new feature"

   # Push new branch to origin
   git push origin feature/new-feature-name
   ```

2. When incorporating upstream updates:
   ```bash
   # Switch to main branch
   git checkout main

   # Get updates from upstream
   git fetch upstream
   git merge upstream/main

   # Push updates to origin
   git push origin main
   ```

## Important Notes

1. **Handling Sensitive Information**
   - `.tfvars` files may contain sensitive information and must be excluded from Git management
   - Ensure `.gitignore` contains appropriate exclusion settings

2. **Resolving Conflicts**
   - When incorporating upstream changes, resolve conflicts carefully
   - If unsure, check Issues and Discussions in the upstream repository

3. **Branch Management**
   - Keep the main branch in a state where it can always be synced with upstream
   - Always do development in a separate branch and merge to main when complete

## Troubleshooting

### Q1: Conflicts occur when incorporating upstream changes
```bash
# Temporarily stash current changes
git stash

# Incorporate upstream changes
git fetch upstream
git merge upstream/main

# After resolving conflicts, commit changes
git add .
git commit -m "Resolve conflicts with upstream"

# Restore stashed changes
git stash pop
```

### Q2: Accidentally committed sensitive information
```bash
# Undo the last commit
git reset --soft HEAD^

# Add the file to .gitignore
echo "sensitive-file-name" >> .gitignore

# Recommit changes
git add .gitignore
git commit -m "Remove sensitive information and update .gitignore"

# Force push (Note: Discuss with team if in team development)
git push origin main --force
```

### Q3: Terraform destroy fails due to deletion protection and dependencies

**Problem**: When running `terraform destroy`, the operation fails with errors related to deletion protection and resource dependencies, making it impossible to cleanly remove resources.

**Common Error Messages**:
```
Error: cannot destroy service without setting deletion_protection=false and running `terraform apply`
Error: Error, failed to deleteuser postgres in instance postgres-instance: googleapi: Error 400: Invalid request: failed to delete user postgres: . role "postgres" cannot be dropped because some objects depend on it
Error: Error deleting bucket: googleapi: Error 409: The bucket you tried to delete was not empty.
```

**Root Causes**:
1. **Deletion Protection**: Cloud SQL and Cloud Run services have deletion protection enabled
2. **Resource Dependencies**: Some resources depend on others and cannot be deleted in the wrong order
3. **Non-empty Resources**: Storage buckets contain objects that prevent deletion
4. **Database Dependencies**: PostgreSQL users have dependencies on database objects

**Solution**: The repository has been updated with the following improvements:

1. **Automatic Deletion Protection Disabling**:
   - Cloud SQL: `deletion_protection = false` in terraform.tfvars
   - Cloud Run: `deletion_protection = false` in module configuration
   - Storage: `force_destroy = true` in module configuration

2. **Proper Resource Dependencies**:
   - Added `depends_on` relationships to ensure correct deletion order
   - Added `lifecycle` blocks with `create_before_destroy = true`

3. **Resource Cleanup Order**:
   - Cloud Run → Cloud SQL → Redis → Filestore → Network → Storage

**Prevention**: Always ensure the following settings are in place:

```hcl
# terraform.tfvars
db_deletion_protection = false

# modules/cloudrun/main.tf
resource "google_cloud_run_v2_service" "dify_service" {
  deletion_protection = false
  # ... other configuration
}

# modules/storage/main.tf
resource "google_storage_bucket" "dify_bucket" {
  force_destroy = true
  # ... other configuration
}
```

**Manual Cleanup (if needed)**:
```bash
# Disable deletion protection manually
gcloud sql instances patch postgres-instance --no-deletion-protection

# Delete Cloud Run services manually
gcloud run services delete dify-service --region=asia-northeast1 --quiet
gcloud run services delete dify-sandbox --region=asia-northeast1 --quiet

# Empty and delete storage bucket
gsutil -m rm -r gs://your-bucket-name/*

# Remove from Terraform state if manually deleted
terraform state rm module.cloudsql.google_sql_database_instance.postgres_instance

### Q4: VPC-related resources cannot be deleted due to Serverless VPC Access reservations

**Problem**: After running `terraform destroy`, VPC network and subnet resources remain because they are being used by Serverless VPC Access reservations that cannot be easily deleted.

**Common Error Messages**:
```
ERROR: (gcloud.compute.networks.subnets.delete) Could not fetch resource:
 - The subnetwork resource is already being used by 'projects/xxx/regions/xxx/addresses/serverless-ipv4-xxx'

ERROR: (gcloud.compute.addresses.delete) Could not fetch resource:
 - The address resource is already being used by '//serverless.googleapis.com/projects/xxx/locations/xxx/addressReservations/serverless-ipv4-xxx'
```

**Root Causes**:
1. **Serverless VPC Access Reservations**: Automatic IP address reservations created by Serverless VPC Access
2. **Permission Issues**: Current account may not have sufficient permissions to manage Serverless VPC Access
3. **Automatic Resource Creation**: These reservations are created automatically and are difficult to remove manually

**Solution**: The following approaches can be used:

1. **Wait for Automatic Cleanup**: Sometimes reservations are automatically released after a few hours
2. **Request Project Admin Assistance**: Ask project administrators to remove Serverless VPC Access reservations
3. **Leave Resources**: VPC resources have minimal cost impact and can be left if deletion is not critical

**Manual Cleanup Attempts**:
```bash
# Try to delete Serverless VPC Access connector (if exists)
gcloud compute networks vpc-access connectors list --region=asia-northeast1 --project=your-project-id

# Try to delete the IP address reservation
gcloud compute addresses delete serverless-ipv4-xxx --region=asia-northeast1 --project=your-project-id

# Try to delete subnet and network (will fail if reservations exist)
gcloud compute networks subnets delete dify-subnet --region=asia-northeast1 --project=your-project-id
gcloud compute networks delete dify-vpc --project=your-project-id
```

**Cost Impact**: VPC networks and subnets have minimal cost (typically less than $1/month), so leaving them is often acceptable. 