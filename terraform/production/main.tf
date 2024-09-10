module "terraform" {
  source                    = "../modules/terraform"
  env                       = local.env
  project                   = local.project
  project_number            = local.project_number
  workload_identity_pool_id = local.workload_identity_pool_id
  repo                      = local.repo
}
module "clubroom" {
  source = "../modules/clubroom"
  env    = "production"
}
