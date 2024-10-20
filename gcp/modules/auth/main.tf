resource "google_firebase_project" "auth" {
  provider = google-beta
  project  = var.project
}
