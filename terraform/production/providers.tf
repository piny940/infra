provider "google" {
  project = local.project
  default_labels = {
    service     = "home-cluster"
    environment = local.env
  }
}
