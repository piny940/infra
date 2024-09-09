provider "google" {
  project = "stg-piny940"
  default_labels = {
    service     = "home-cluster"
    environment = "staging"
  }
}
