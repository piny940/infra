resource "google_iam_workload_identity_pool_provider" "home_kubernetes" {
  workload_identity_pool_id          = var.workload_identity_pool_id
  workload_identity_pool_provider_id = "home-kubernetes"
  display_name                       = "Home Kubernetes"
  description                        = "for Kubernetes in the home"
  attribute_mapping = {
    "google.subject" = "assertion.sub"
  }
  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}
