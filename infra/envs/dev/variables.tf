variable "prefix" {
  description = "Same prefix used in the bootstrap: projects are <prefix>-shared and <prefix>-<environment>."
  type        = string
}

variable "environment" {
  type = string

  validation {
    condition     = contains(["dev", "stage"], var.environment)
    error_message = "environment must be dev or stage."
  }
}

variable "region" {
  type    = string
  default = "us-central1"
}

variable "labels" {
  type = map(string)
  default = {
    managed-by = "terraform"
    platform   = "ai"
  }
}

# ---------- Network ----------

variable "subnet_cidr" {
  description = "Subnet used by Cloud Run Direct VPC egress. Must not overlap with any network you peer or connect to."
  type        = string
}

variable "psa_cidr" {
  description = "Private Service Access range (Cloud SQL private IP)."
  type        = string
}

# Layers, switched on one at a time. Each layer only depends on the previous ones.
variable "enable_network" {
  type    = bool
  default = false
}

variable "enable_sql" {
  type    = bool
  default = false
}

variable "enable_iam" {
  type    = bool
  default = false
}

variable "enable_run" {
  type    = bool
  default = false
}

variable "enable_edge" {
  type    = bool
  default = false
}

# ---------- Cloud SQL ----------

variable "sql_tier" {
  type    = string
  default = "db-f1-micro"
}

variable "sql_deletion_protection" {
  type    = bool
  default = true
}

variable "sql_backup_start_time" {
  description = "Daily backup start (HH:MM, UTC). With the dev schedule on, pick a time when the instance is running."
  type        = string
  default     = "05:00"
}

variable "db_name" {
  type    = string
  default = "app"
}

variable "db_user" {
  type    = string
  default = "app"
}

variable "sql_password_version" {
  description = "Increment to rotate the app user password (database + secret). See docs/runbooks/rotate-db-password.md."
  type        = number
  default     = 1
}

variable "sql_schedule" {
  description = "Stop the instance in the evening and start it in the morning on weekdays. dev only."
  type        = bool
  default     = false

  validation {
    condition     = !var.sql_schedule || var.environment == "dev"
    error_message = "sql_schedule is only supported in dev."
  }
}

variable "sql_schedule_time_zone" {
  description = "IANA time zone of the start/stop jobs, e.g. America/Chicago or America/Sao_Paulo."
  type        = string
  default     = "Etc/UTC"
}

variable "sql_stop_cron" {
  type    = string
  default = "0 20 * * 1-5"
}

variable "sql_start_cron" {
  description = "Starting a stopped instance takes about 10-15 minutes: schedule it ahead of the workday."
  type        = string
  default     = "45 6 * * 1-5"
}

# ---------- Groups ----------

variable "group_domain" {
  type = string
}

variable "group_admins_name" {
  type    = string
  default = "ai-admins"
}

variable "group_devs_name" {
  type    = string
  default = "ai-devs"
}

variable "group_users_name" {
  type    = string
  default = "ai-users"
}

# ---------- Vertex AI ----------

variable "vertex_project_id" {
  description = "Project where Vertex AI is consumed. Empty: this environment's own project (aiplatform API enabled here)."
  type        = string
  default     = ""
}

variable "vertex_location" {
  type    = string
  default = "global"
}

variable "vertex_model" {
  type    = string
  default = "gemini-2.5-flash"
}

# ---------- Cloud Run ----------

variable "hello_image" {
  description = "Image of the validation service, pinned by digest."
  type        = string
  default     = ""

  validation {
    condition     = var.hello_image == "" || can(regex("@sha256:[0-9a-f]{64}$", var.hello_image))
    error_message = "hello_image must be pinned by digest (...@sha256:<64 hex>)."
  }
}

variable "run_deletion_protection" {
  type    = bool
  default = true
}
