resource "google_storage_bucket" "clubroom" {
  name     = format("%sclubroom.piny940.com", local.prefix)
  location = "asia-southeast1"

  public_access_prevention    = "inherited"
  uniform_bucket_level_access = true
}
