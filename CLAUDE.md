# CLAUDE.md

Guidance for Claude Code when working in this repository.

## What this is

A Terraform blueprint for a dev/demo AI platform on Google Cloud (Cloud Run + IAP, private
Cloud SQL, Vertex AI) with keyless Azure DevOps pipelines. See README.md for the architecture
and the reasoning behind each decision.

## Layout

- `infra/bootstrap` - folder, projects, groups, org policy, state bucket, registries, deployer@, WIF.
- `infra/modules` - project, network, cloudsql, run-service.
- `infra/envs/dev`, `infra/envs/stage` - the SAME code; only `terraform.tfvars` and the backend
  prefix differ. Change both directories together and keep them identical.
- `pipeline-templates` - Azure DevOps template repo (Validate, Build, Deploy to dev, Promote).
- `app-template` - example app and the `azure-pipelines.yml` that extends the template.
- `README.md` (English) and `README.pt-BR.md` (Brazilian Portuguese) - the same content in two
  languages. Always update both together, keeping sections, tables, diagrams and links in sync.

## Rules

- Never run `terraform apply`, `destroy` or `-auto-approve` without explicit confirmation from
  the user. Show the `plan` summary first.
- Never commit `terraform.tfvars`, state files, `.terraform/`, keys or tokens. Only
  `*.tfvars.example` with fictitious values.
- IAM is always additive: `google_*_iam_member`, never `_binding` or `_policy` (the only
  exceptions are the state bucket's deliberate authoritative policy).
- No service account keys. Pipelines authenticate through Workload Identity Federation.
- Images are always deployed by digest. Stage only runs images from the `apps` repository.
- Keep the layered rollout: a new resource belongs to one `enable_*` layer and may only depend
  on earlier layers. Do not use `-target`.
- Secrets use write-only arguments (`*_wo`) and ephemeral values so they never reach the state.
- Every pipeline bash script starts with `set -euo pipefail` and fails closed.

## Checks before committing

```bash
terraform fmt -recursive -check infra
for d in infra/bootstrap infra/envs/dev infra/envs/stage; do
  (cd "$d" && terraform init -backend=false -input=false >/dev/null && terraform validate)
done
python -c "import yaml,glob; [yaml.safe_load(open(f)) for f in glob.glob('**/*.yml', recursive=True)]"
```
