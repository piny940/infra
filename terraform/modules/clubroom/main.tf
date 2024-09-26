resource "google_storage_bucket" "clubroom" {
  name     = format("%sclubroom.piny940.com", local.prefix)
  location = "asia-southeast1"

  public_access_prevention    = "inherited"
  uniform_bucket_level_access = true
}

resource "google_project_iam_member" "clubroom_k8s_storage_object_user" {
  project = var.project
  role    = "roles/storage.objectUser"
  member  = "principal://iam.googleapis.com/projects/${var.project_number}/locations/global/workloadIdentityPools/${var.workload_identity_pool_id}/subject/system:serviceaccount:default:clubroom"
}
