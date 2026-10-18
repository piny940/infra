module "workload_identity_pool" {
  source  = "../modules/workload_identity_pool"
  project = local.project
}
data "local_file" "cluster_jwks" {
  filename = "${path.module}/cluster-jwks.json"
}
module "terraform" {
  source                    = "../modules/terraform"
  env                       = local.env
  project                   = local.project
  project_number            = local.project_number
  workload_identity_pool_id = module.workload_identity_pool.workload_identity_pool_id
  repo                      = local.repo
  branch                    = "staging"
}
