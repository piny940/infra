resource "google_storage_bucket" "clubroom" {
  name     = format("%sclubroom.piny940.com", local.prefix)
  location = "asia-southeast1"

  public_access_prevention    = "inherited"
  uniform_bucket_level_access = true
}
resource "google_service_account" "clubroom" {
  account_id                   = "clubroom"
  display_name                 = "Clubroom"
  create_ignore_already_exists = true
}
resource "google_project_iam_member" "clubroom_storage_object_user" {
  project = var.project
  member  = "serviceAccount:${google_service_account.clubroom.email}"
  role    = "roles/storage.objectUser"
}
resource "google_project_iam_member" "clubroom_service_account_token_creator" {
  project = var.project
  member  = "serviceAccount:${google_service_account.clubroom.email}"
  role    = "roles/iam.serviceAccountTokenCreator"
}
resource "google_project_iam_member" "clubroom_workload_identity_user" {
  project = var.project
  member  = "serviceAccount:${google_service_account.clubroom.email}"
  role    = "roles/iam.workloadIdentityUser"
}
resource "google_service_account_iam_member" "ksa_workload_identity_user" {
  service_account_id = google_service_account.clubroom.id
  role               = "roles/iam.workloadIdentityUser"
  member             = "principal://iam.googleapis.com/projects/${var.project_number}/locations/global/workloadIdentityPools/${var.workload_identity_pool_id}/subject/system:serviceaccount:default:${local.prefix}clubroom"
}
