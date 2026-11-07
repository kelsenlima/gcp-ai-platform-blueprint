variable "project_id" {
  type = string
}

variable "name" {
  type = string
}

variable "folder_id" {
  type = string
}

variable "billing_account" {
  type = string
}

variable "labels" {
  type    = map(string)
  default = {}
}

variable "services" {
  description = "APIs to enable on the project."
  type        = list(string)
  default     = []
}

variable "auto_create_network" {
  description = "false deletes the default network (the provider enables the Compute API to do so)."
  type        = bool
  default     = true
}
