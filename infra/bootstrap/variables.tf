# ---------- Organization ----------

variable "org_id" {
  description = "Numeric ID of the Google Cloud organization."
  type        = string
}

variable "customer_id" {
  description = "Directory customer ID (gcloud organizations describe <org_id> --format='value(owner.directoryCustomerId)')."
  type        = string
}

variable "billing_account" {
  description = "Billing account linked to the three projects. Changing it later updates the projects in place."
  type        = string
}

variable "folder_name" {
  description = "Display name of the folder that holds the platform projects."
  type        = string
  default     = "AI Platform"
}

variable "prefix" {
  description = "Prefix of the project IDs: <prefix>-shared, <prefix>-dev, <prefix>-stage. Project IDs are global, so pick something unique."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{3,22}$", var.prefix))
    error_message = "Use 4-23 lowercase letters, digits or hyphens, starting with a letter (the longest project ID suffix is -shared)."
  }
}

variable "region" {
  description = "Region for every regional resource."
  type        = string
  default     = "us-central1"
}

variable "labels" {
  description = "Labels applied to every project and labelled resource."
  type        = map(string)
  default = {
    managed-by = "terraform"
    platform   = "ai"
  }
}

# ---------- Groups ----------

variable "manage_groups" {
  description = "true: create the three groups with the Cloud Identity API. false: the groups already exist."
  type        = bool
  default     = true
}

variable "group_domain" {
  description = "Domain of the group e-mails (a domain verified in the directory)."
  type        = string
}

variable "group_admins_name" {
  description = "Platform administrators (owners of the folder)."
  type        = string
  default     = "ai-admins"
}

variable "group_devs_name" {
  description = "Developers (deploy and operate in dev, read-only in stage)."
  type        = string
  default     = "ai-devs"
}

variable "group_users_name" {
  description = "Users (access the apps and demos in stage through IAP)."
  type        = string
  default     = "ai-users"
}

# ---------- Azure DevOps federation (keyless, deployer@) ----------

variable "azdo_org_name" {
  description = "Azure DevOps organization name (only used in descriptions)."
  type        = string
}

variable "azdo_project_name" {
  description = "Azure DevOps project name (only used in descriptions)."
  type        = string
}

variable "azdo_service_connection_name" {
  description = "Name of the Azure DevOps service connection used by the pipelines (only used in descriptions)."
  type        = string
}

variable "azdo_tenant_id" {
  description = "Microsoft Entra tenant that issues the service connection tokens."
  type        = string
}

variable "azdo_org_id" {
  description = "ID (GUID) of the Azure DevOps organization."
  type        = string
}

variable "azdo_service_connection_id" {
  description = "ID (GUID) of the service connection. Only this subject can act as deployer@."
  type        = string
}

variable "azdo_token_audiences" {
  description = "Accepted 'aud' values. Decode one token from your service connection and use exactly what it carries (see docs/azure-devops-federation.md)."
  type        = list(string)
  default     = ["api://AzureADTokenExchange"]
}
