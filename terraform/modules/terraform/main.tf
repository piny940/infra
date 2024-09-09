resource "google_iam_workload_identity_pool" "default" {
  workload_identity_pool_id = "default"
}

resource "google_iam_workload_identity_pool_provider" "terraform_github_actions" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.default.workload_identity_pool_id
  workload_identity_pool_provider_id = "terraform-github-actions"
  display_name                       = "Terrform GitHub Actions"
  description                        = "for Terraform GitHub Actions"
  attribute_condition                = format("assertion.repository == \"%s\" && assertion.environment == \"%s\"", local.repo, var.env)
  attribute_mapping = {
    "google.subject" = "assertion.repository"
  }
  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

resource "google_service_account" "terraform_github_actions" {
  account_id                   = "terraform-github-actions"
  display_name                 = "Terraform GitHub Actions"
  create_ignore_already_exists = true
}
resource "google_project_iam_member" "terraform_github_actions_workload_identity_user" {
  project = var.project
  member  = google_service_account.terraform_github_actions.email
  role    = "roles/iam.workloadIdentityUser"
}

resource "google_project_iam_member" "terraform_github_actions_workload_identity_user" {
  project = var.project
  member  = google_service_account.terraform_github_actions.email
  role    = "roles/editor"
}
