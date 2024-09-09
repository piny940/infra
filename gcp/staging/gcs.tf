resource "google_storage_bucket" "clubroom" {
  name     = "com.piny940.clubroom"
  location = "asia-southeast1"

  public_access_prevention    = "inherited"
  uniform_bucket_level_access = true
}
