provider "google" {
  project = "stg-piny940"
  default_labels = {
    service     = "home-cluster"
    environment = "staging"
  }
}

resource "random_id" "terraform_remote_backend" {
  byte_length = 8
}

resource "google_storage_bucket" "terraform_remote_backend" {
  name     = "${random_id.terraform_remote_backend.hex}-terraform-remote-backend"
  location = "US"

  force_destroy               = false
  public_access_prevention    = "enforced"
  uniform_bucket_level_access = true
}

resource "local_file" "backend" {
  file_permission = "0644"
  filename        = "${path.module}/backend.tf"

  content = <<-EOT
  terraform {
    backend "gcs" {
      bucket = "${google_storage_bucket.terraform_remote_backend.name}"
    }
  }
  EOT
}
