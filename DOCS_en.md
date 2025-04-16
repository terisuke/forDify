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