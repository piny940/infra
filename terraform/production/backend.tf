resource "google_storage_bucket" "terraform_remote_backend" {
  name     = "terraform-remote-backend.piny940.com"
  location = "US"

  force_destroy               = false
  public_access_prevention    = "enforced"
  uniform_bucket_level_access = true
}

terraform {
  backend "gcs" {
    bucket = "terraform-remote-backend.piny940.com"
  }
}
