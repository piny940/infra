resource "google_storage_bucket" "portfolio" {
  name     = "${local.prefix}portfolio.piny940.com"
  location = "asia-southeast1"

  public_access_prevention    = "inherited"
  uniform_bucket_level_access = true
}
resource "google_service_account" "portfolio" {
  account_id                   = "portfolio"
  display_name                 = "Portfolio"
  create_ignore_already_exists = true
}
resource "google_project_iam_member" "portfolio_storage_object_user" {
  project = var.project
  member  = "serviceAccount:${google_service_account.portfolio.email}"
  role    = "roles/storage.objectUser"
}
resource "google_project_iam_member" "portfolio_workload_identity_user" {
  project = var.project
  member  = "serviceAccount:${google_service_account.portfolio.email}"
  role    = "roles/iam.workloadIdentityUser"
}
resource "google_project_iam_member" "all_users_storage_object_viewer" {
  project = var.project
  member  = "allUsers"
  role    = "roles/storage.objectViewer"
}
resource "google_service_account_iam_member" "ksa_workload_identity_user" {
  service_account_id = google_service_account.portfolio.id
  role               = "roles/iam.workloadIdentityUser"
  member             = "principal://iam.googleapis.com/projects/${var.project_number}/locations/global/workloadIdentityPools/${var.workload_identity_pool_id}/subject/system:serviceaccount:default:${local.prefix}portfolio"
}

