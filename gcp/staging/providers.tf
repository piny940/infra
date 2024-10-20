provider "google" {
  project = local.project
  default_labels = {
    service     = "home-cluster"
    environment = local.env
  }
}
terraform {
  required_providers {
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.0"
    }
  }
}
provider "google-beta" {
  project = local.project
  default_labels = {
    service     = "home-cluster"
    environment = local.env
  }
}
