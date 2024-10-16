provider "aws" {
  region = "ap-northeast-1"
}

# 高いのでsecret managerだけGCPを使う
provider "google" {
  project = local.gcp_project
  default_labels = {
    service     = "home-cluster"
    environment = local.env
  }
}

