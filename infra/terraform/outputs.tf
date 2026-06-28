output "worker_name" {
  description = "Deployed Worker script name."
  value       = cloudflare_workers_script.scheduler.script_name
}

output "cron_schedules" {
  description = "Active cron schedules on the scheduler Worker (UTC)."
  value       = local.cron_schedules
}
