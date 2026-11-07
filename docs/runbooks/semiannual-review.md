# Runbook: semiannual review

Every six months an administrator goes through this checklist and records the result.

## People and access

- [ ] Group members reviewed with their managers; people who left or changed roles removed.

  ```bash
  for g in ai-admins ai-devs ai-users; do
    echo "== $g"
    gcloud identity groups memberships list --group-email=$g@<group-domain> \
      --billing-project=<prefix>-shared --format="value(preferredMemberKey.id,roles[].name.list())"
  done
  ```

  `--billing-project` is needed because the Cloud Identity API is only enabled in the shared
  project.
- [ ] The admins group has at least two people and no developers.
- [ ] Azure DevOps: Project Administrators only has administrators; no administrator reaches
  Contributors, directly or through a team; Endpoint Creators/Administrators only has
  administrators.

## Pipelines and apps

- [ ] Each pipeline authorized on the service connection matches a live app, and the service
  connection is still **not** open to all pipelines.
- [ ] The *Required template* check is still in place.
- [ ] Abandoned apps removed from dev and stage (Cloud Run service, app secrets, pipeline
  authorization).

## Database and Terraform

- [ ] Database password rotated in dev and stage ([rotate-db-password.md](rotate-db-password.md)).
- [ ] Backup restore tested on a `tmp-` instance ([restore-backup.md](restore-backup.md), path A).
- [ ] Provider versions: compare `.terraform.lock.hcl` with the latest `hashicorp/google`
  release, read the changelog, bump `versions.tf`, run `terraform init -upgrade` and `plan` in
  bootstrap, dev and stage; apply only if nothing unexpected changes.
- [ ] No drift: `terraform plan -detailed-exitcode` returns `0` in `infra/bootstrap`,
  `infra/envs/dev` (database running) and `infra/envs/stage`. Any difference is drift: find out
  who changed what and why before applying.

## Cost

- [ ] Budgets exist and alert at an adequate amount.
- [ ] Actual cost per project and service over the last six months, and Vertex AI cost split
  by the `environment` and `app` labels.
