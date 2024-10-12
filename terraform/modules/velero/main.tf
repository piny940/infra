resource "google_storage_bucket" "velero" {
  name     = "${local.prefix}velero-cluster-backup.piny940.com"
  location = "us-central1"

  public_access_prevention    = "inherited"
  uniform_bucket_level_access = true
  storage_class               = "NEARLINE"
}
resource "google_service_account" "velero" {
  account_id                   = "velero"
  display_name                 = "Velero"
  create_ignore_already_exists = true
}
resource "google_project_iam_member" "velero_storage_object_user" {
  project = var.project
  member  = "serviceAccount:${google_service_account.velero.email}"
  role    = "roles/storage.objectUser"
}
resource "google_project_iam_member" "velero_service_account_token_creator" {
  project = var.project
  member  = "serviceAccount:${google_service_account.velero.email}"
  role    = "roles/iam.serviceAccountTokenCreator"
}
resource "google_service_account_iam_member" "ksa_velero_workload_identity_user" {
  service_account_id = google_service_account.velero.id
  role               = "roles/iam.workloadIdentityUser"
  member             = "principal://iam.googleapis.com/projects/${var.project_number}/locations/global/workloadIdentityPools/${var.workload_identity_pool_id}/subject/system:serviceaccount:velero:${local.prefix}velero"
}
