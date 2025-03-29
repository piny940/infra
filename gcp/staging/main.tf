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
}
module "kube_workload_identity" {
  source                                      = "../modules/kube_workload_identity"
  env                                         = local.env
  project                                     = local.project
  project_number                              = local.project_number
  workload_identity_pool_id                   = module.workload_identity_pool.workload_identity_pool_id
  home_kubernetes_cluster_jwks_secret_version = "4"
  cluster_jwks                                = data.local_file.cluster_jwks.content
}
module "clubroom" {
  source                    = "../modules/clubroom"
  project                   = local.project
  env                       = local.env
  project_number            = local.project_number
  workload_identity_pool_id = module.workload_identity_pool.workload_identity_pool_id
}
module "portfolio" {
  source                    = "../modules/portfolio"
  env                       = local.env
  project                   = local.project
  project_number            = local.project_number
  workload_identity_pool_id = module.workload_identity_pool.workload_identity_pool_id
}
