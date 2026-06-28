variable "cloudflare_account_id" {
  type        = string
  description = "Cloudflare account ID that owns the Worker."
}

variable "github_owner" {
  type        = string
  description = "Owner of the GitHub repository whose Actions workflows are dispatched."
  default     = "v420v"
}

variable "github_repo" {
  type        = string
  description = "Name of the GitHub repository."
  default     = "autopilot"
}

variable "git_ref" {
  type        = string
  description = "Git ref (branch or tag) the dispatched workflows run on."
  default     = "main"
}

variable "github_token" {
  type        = string
  sensitive   = true
  description = <<-EOT
    GitHub token the Worker uses to call the workflow_dispatch API.
    Fine-grained PAT scoped to the repo with "Actions: Read and write",
    or a classic PAT with repo + workflow scope. Stored as a Worker
    secret_text binding (and therefore in Terraform state — keep state private).
    Set it via the TF_VAR_github_token environment variable.
  EOT
}

variable "worker_name" {
  type        = string
  description = "Name of the Cloudflare Worker script."
  default     = "autopilot-scheduler"
}
