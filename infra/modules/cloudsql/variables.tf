variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "name" {
  description = "Instance name."
  type        = string
}

variable "tier" {
  type = string
}

variable "network_id" {
  type = string
}

variable "psa_connection" {
  description = "Private Service Access connection ID (only used to order creation)."
  type        = string
}

variable "deletion_protection" {
  type = bool
}

variable "backup_start_time" {
  description = "Daily backup start (HH:MM, UTC). Must fall in a window when the instance is running."
  type        = string
}

variable "db_name" {
  type = string
}

variable "db_user" {
  type = string
}

variable "password" {
  description = "Password of the app user. Ephemeral: only sent through write-only arguments."
  type        = string
  sensitive   = true
  ephemeral   = true
}

variable "password_version" {
  description = "Increment to write a new password to the database and to the secret."
  type        = number
}

variable "labels" {
  type    = map(string)
  default = {}
}
