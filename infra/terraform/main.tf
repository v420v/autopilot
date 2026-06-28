locals {
  worker_entry = "${path.module}/../scheduler/dist/index.js" # build first: cd ../scheduler && npm run build

  # Keep in sync with the SCHEDULES map in ../scheduler/src/index.ts.
  cron_schedules = [
    "*/15 * * * *", # review/fix loop + resolve-conflicts + slack
    "0 18 * * *",   # 03:00 JST daily: suggest-issues (kicks the implement chain)
  ]
}

resource "cloudflare_workers_script" "scheduler" {
  account_id  = var.cloudflare_account_id
  script_name = var.worker_name

  # content_file keeps the (potentially large) script body out of Terraform
  # state; content_sha256 makes Terraform redeploy when the source changes.
  content_file   = local.worker_entry
  content_sha256 = filesha256(local.worker_entry)
  main_module    = "index.js" # ES module entrypoint (basename of content_file)

  compatibility_date = "2025-06-01"

  bindings = [
    {
      name = "GITHUB_OWNER"
      type = "plain_text"
      text = var.github_owner
    },
    {
      name = "GITHUB_REPO"
      type = "plain_text"
      text = var.github_repo
    },
    {
      name = "GIT_REF"
      type = "plain_text"
      text = var.git_ref
    },
    {
      name = "GITHUB_TOKEN"
      type = "secret_text"
      text = var.github_token
    },
  ]
}

resource "cloudflare_workers_cron_trigger" "scheduler" {
  account_id  = var.cloudflare_account_id
  script_name = cloudflare_workers_script.scheduler.script_name

  schedules = [for cron in local.cron_schedules : { cron = cron }]
}
