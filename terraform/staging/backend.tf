provider "google" {
  project = local.project
  default_labels = {
    service     = "home-cluster"
    environment = local.env
  }
}

resource "google_storage_bucket" "terraform_remote_backend" {
  name     = "stg-terraform-remote-backend.piny940.com"
  location = "US"

  force_destroy               = false
  public_access_prevention    = "enforced"
  uniform_bucket_level_access = true
}

terraform {
  backend "gcs" {
    bucket = "stg-terraform-remote-backend.piny940.com"
  }
}
