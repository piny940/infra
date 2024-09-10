data "google_client_config" "current" {}

resource "google_iam_workload_identity_pool" "default" {
  workload_identity_pool_id = "default"
}
module "terraform" {
  source = "../modules/terraform"
  env = local.env
  project = local.project
  project_number = local.project_number
  workload_identity_pool_id = google_iam_workload_identity_pool.default.workload_identity_pool_id
  repo = local.repo
}
module "clubroom" {
  source = "../modules/clubroom"
  env    = local.env
}
