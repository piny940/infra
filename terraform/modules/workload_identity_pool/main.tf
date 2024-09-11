resource "google_project_service" "iamcredentials" {
  project = var.project
  service = "iamcredentials.googleapis.com"
}
resource "google_iam_workload_identity_pool" "default" {
  workload_identity_pool_id = "pool"
}
