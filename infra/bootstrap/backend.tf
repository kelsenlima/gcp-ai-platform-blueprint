# Partial GCS backend. The bucket is created by this bootstrap itself, so the FIRST run uses
# local state: rename this file to backend.tf.off, run init/apply, rename it back and migrate:
#
#   terraform init -migrate-state -backend-config="bucket=<prefix>-tfstate"
#
# See README.md, "Deploy to your own organization".
terraform {
  backend "gcs" {
    prefix = "bootstrap"
  }
}
