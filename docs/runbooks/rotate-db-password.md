# Runbook: rotate the database password

The app user password is generated as an ephemeral value and sent through write-only
arguments: it is never in the Terraform state or plan. It is rewritten only when
`sql_password_version` changes.

> **dev with the schedule on:** the instance must be running (`RUNNABLE` / `ALWAYS`) before
> `plan`, or the plan fails with "instance is not running". Start it first
> ([start/stop runbook](start-stop-dev-database.md)).

1. In `infra/envs/<environment>/terraform.tfvars`, increment `sql_password_version`.
2. `terraform plan`. Expected: the user updated in place and the secret version replaced
   (the new one is created, the previous one destroyed). The password is not shown. Then `apply`.
3. **Running apps lose the database until they get a new revision.** The password reaches the
   app as `DB_PASSWORD` (secret `ai-pg-<environment>-app-password:latest`), read only when an
   instance starts. List the services that use the secret:

   ```bash
   P=<prefix>-<environment>; R=<region>; S=ai-pg-<environment>-app-password
   for s in $(gcloud run services list --project=$P --region=$R --format="value(metadata.name)" | tr -d '\r'); do
     gcloud run services describe "$s" --project=$P --region=$R --format=json | grep -q "$S" && echo "$s"
   done
   ```

4. Force a new revision of each listed service:
   - **Pipeline apps:** re-run the pipeline (dev: on `develop`; stage: on `main`), or
     `gcloud run services update <service> --project=$P --region=$R --revision-suffix=pw-v<N>`.
   - **`hello`** (managed by Terraform): nothing to do. `DB_PASSWORD_VERSION` follows
     `sql_password_version`, so the apply in step 2 already created a new revision. Do not run
     `gcloud run services update` on it: that leaves drift until the next apply.
5. Test: `/api/check/db` returns `{"db":"ok"}` (through the browser, because of IAP), and each
   listed app reaches the database again.
