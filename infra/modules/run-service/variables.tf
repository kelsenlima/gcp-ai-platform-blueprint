variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "name" {
  type = string
}

variable "image" {
  description = "Image pinned by digest (.../apps/<app>@sha256:...)."
  type        = string
}

variable "service_account" {
  description = "Runtime service account e-mail (run-runtime@)."
  type        = string
}

variable "network" {
  type = string
}

variable "subnetwork" {
  type = string
}

variable "ingress" {
  description = "INGRESS_TRAFFIC_ALL or INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER."
  type        = string
}

variable "env" {
  type    = map(string)
  default = {}
}

variable "secret_env" {
  description = "Environment variable => secret ID (always the latest version)."
  type        = map(string)
  default     = {}
}

variable "health_path" {
  type    = string
  default = "/api/health"
}

variable "max_instances" {
  type    = number
  default = 2
}

variable "deletion_protection" {
  type    = bool
  default = true
}

variable "iap_enabled" {
  description = "IAP directly on Cloud Run (no load balancer)."
  type        = bool
  default     = false
}

variable "labels" {
  type    = map(string)
  default = {}
}
