# Runbook: start and stop the dev database

With `sql_schedule = true`, two Cloud Scheduler jobs flip the instance `activationPolicy`
(`ALWAYS`/`NEVER`) through the Cloud SQL Admin API, using a dedicated `sql-scheduler@`
service account. `activation_policy` is in `ignore_changes`, so the schedule creates no drift.

| Action | How |
|---|---|
| Start now (~10-15 min) | `gcloud scheduler jobs run sql-start --location=<region> --project=<prefix>-dev` |
| Stop now | `gcloud scheduler jobs run sql-stop --location=<region> --project=<prefix>-dev` |
| Check | `gcloud sql instances describe ai-pg-dev --project=<prefix>-dev --format="value(state,settings.activationPolicy)"` (`RUNNABLE` + `ALWAYS` = running) |
| Turn the schedule off | `sql_schedule = false` in dev's `terraform.tfvars`, then plan/apply (the instance stays on) |
| Change the times | `sql_start_cron`, `sql_stop_cron` and `sql_schedule_time_zone` |

Developers have `roles/cloudscheduler.jobRunner` in dev, so they can start the database
outside working hours themselves.

Keep `sql_backup_start_time` (UTC) inside the window when the instance is running.
