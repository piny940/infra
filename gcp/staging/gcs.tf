resource "google_storage_bucket" "clubroom" {
  name     = "clubroom.piny940.com"
  location = "asia-southeast1"

  public_access_prevention    = "inherited"
  uniform_bucket_level_access = true
}
