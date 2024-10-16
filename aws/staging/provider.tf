provider "aws" {
  region = "ap-northeast-1"
}
provider "google" {
  project = local.gcp_project
  default_labels = {
    service     = "home-cluster"
    environment = local.env
  }
}
