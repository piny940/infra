resource "google_project_service" "default" {
  project = local.project
  for_each = toset([
    "cloudbilling.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "firebase.googleapis.com",
    # Enabling the ServiceUsage API allows the new project to be quota checked from now on.
    "serviceusage.googleapis.com",
  ])
  service = each.key
}
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
  repo                      = local.repo
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
module "auth" {
  source  = "../modules/auth"
  env     = local.env
  project = local.project
}

