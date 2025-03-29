resource "google_service_account" "terraform_github_actions" {
  account_id                   = "terraform-github-actions"
  display_name                 = "Terraform GitHub Actions"
  create_ignore_already_exists = true
}
resource "google_project_iam_member" "terraform_github_actions_owner" {
  project = var.project
  member  = "serviceAccount:${google_service_account.terraform_github_actions.email}"
  role    = "roles/owner"
}
resource "google_project_iam_member" "terraform_github_actions_workload_identity_user" {
  project = var.project
  member  = "serviceAccount:${google_service_account.terraform_github_actions.email}"
  role    = "roles/iam.workloadIdentityUser"
}

resource "google_iam_workload_identity_pool_provider" "repo_github_actions" {
  workload_identity_pool_id          = var.workload_identity_pool_id
  workload_identity_pool_provider_id = "repo-github-actions"
  display_name                       = "Terrform GitHub Actions"
  description                        = "for Terraform GitHub Actions"
  attribute_condition                = "assertion.repository == \"${var.repo}\""
  attribute_mapping = {
    "google.subject" = "assertion.sub"
  }
  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}
resource "google_service_account_iam_member" "terraform_github_actions_env_workload_identity_user" {
  service_account_id = google_service_account.terraform_github_actions.id
  role               = "roles/iam.workloadIdentityUser"
  member             = "principal://iam.googleapis.com/projects/${var.project_number}/locations/global/workloadIdentityPools/${var.workload_identity_pool_id}/subject/repo:${var.repo}:environment:${var.env}"
}
resource "google_service_account_iam_member" "terraform_github_actions_pull_request_workload_identity_user" {
  service_account_id = google_service_account.terraform_github_actions.id
  role               = "roles/iam.workloadIdentityUser"
  member             = "principal://iam.googleapis.com/projects/${var.project_number}/locations/global/workloadIdentityPools/${var.workload_identity_pool_id}/subject/repo:${var.repo}:pull_request"
}
resource "google_service_account_iam_member" "terraform_github_actions_branch_workload_identity_user" {
  service_account_id = google_service_account.terraform_github_actions.id
  role               = "roles/iam.workloadIdentityUser"
  member             = "principal://iam.googleapis.com/projects/${var.project_number}/locations/global/workloadIdentityPools/${var.workload_identity_pool_id}/subject/repo:${var.repo}:ref:refs/heads/${var.branch}"
}
