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

locals {
  repo = "piny940/infra"
}
