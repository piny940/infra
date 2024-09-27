resource "google_secret_manager_secret" "home_kubernetes_cluster_jwks" {
  secret_id = "home-kubernetes-cluster-jwks"
  replication {
    auto {}
  }
}
data "google_secret_manager_secret_version" "home_kubernetes_cluster_jwks" {
  secret  = google_secret_manager_secret.home_kubernetes_cluster_jwks.secret_id
  version = "1"
}
resource "google_iam_workload_identity_pool_provider" "home_kubernetes" {
  workload_identity_pool_id          = var.workload_identity_pool_id
  workload_identity_pool_provider_id = "home-kubernetes"
  display_name                       = "Home Kubernetes"
  description                        = "for Kubernetes in the home"
  attribute_mapping = {
    "google.subject" = "assertion.sub"
  }
  oidc {
    issuer_uri = "https://kubernetes.default.svc.cluster.local"
    jwks_json  = data.google_secret_manager_secret_version.home_kubernetes_cluster_jwks.secret_data
  }
}
