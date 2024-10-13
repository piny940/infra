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
