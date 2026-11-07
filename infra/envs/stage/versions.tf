terraform {
  required_version = ">= 1.11" # write-only arguments (Cloud SQL password)

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 7.0" # google_project_service_identity
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7" # ephemeral "random_password"
    }
  }

  # Partial configuration: terraform init -backend-config="bucket=<prefix>-tfstate"
  backend "gcs" {
    prefix = "stage"
  }
}
