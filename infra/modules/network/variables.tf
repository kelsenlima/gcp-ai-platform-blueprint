variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "name" {
  description = "VPC name."
  type        = string
  default     = "ai-vpc"
}

variable "subnet_cidr" {
  description = "Primary range of the regional subnet used by Cloud Run Direct VPC egress, e.g. 10.20.0.0/24."
  type        = string
}

variable "psa_cidr" {
  description = "Range reserved for Private Service Access (Cloud SQL), e.g. 10.21.0.0/16."
  type        = string
}

variable "labels" {
  type    = map(string)
  default = {}
}
