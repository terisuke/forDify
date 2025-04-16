terraform {
  backend "gcs" {
    bucket = "fordify-455606-tfstate" # replace with your bucket name
    prefix = "dify"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}