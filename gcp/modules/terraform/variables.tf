variable "env" {
  type = string

  validation {
    condition     = var.env == "staging" || var.env == "production"
    error_message = "value must be either 'staging' or 'production'"
  }
}
variable "project" {
  type = string
}
variable "project_number" {
  type = number
}
variable "workload_identity_pool_id" {
  type = string
}
variable "repo" {
  type = string
}
variable "branch" {
  type = string
}
