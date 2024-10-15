module "workload_identity_pool" {
  source  = "../modules/workload_identity_pool"
  project = local.project
}
module "terraform" {
  source                    = "../modules/terraform"
  env                       = local.env
  project                   = local.project
  project_number            = local.project_number
  workload_identity_pool_id = module.workload_identity_pool.workload_identity_pool_id
  repo                      = "piny940/infra"
}
module "kube_workload_identity" {
  source                                      = "../modules/kube_workload_identity"
  env                                         = local.env
  project                                     = local.project
  project_number                              = local.project_number
  workload_identity_pool_id                   = module.workload_identity_pool.workload_identity_pool_id
  home_kubernetes_cluster_jwks_secret_version = "1"
}
module "clubroom" {
  source                    = "../modules/clubroom"
  env                       = local.env
  project                   = local.project
  project_number            = local.project_number
  workload_identity_pool_id = module.workload_identity_pool.workload_identity_pool_id
}
module "velero" {
  source                    = "../modules/velero"
  env                       = local.env
  project                   = local.project
  project_number            = local.project_number
  workload_identity_pool_id = module.workload_identity_pool.workload_identity_pool_id
}
