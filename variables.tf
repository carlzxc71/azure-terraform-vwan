variable "environment" {
  description = "The environment for which the resources are being created (e.g., dev, staging, prod)."
  type        = string
}

variable "location" {
  description = "The Azure region where the resources will be deployed."
  type        = string
}

variable "location_short" {
  description = "Short name for the Azure region, used in resource names."
  type        = string
}

variable "vm_password" {
  type      = string
  sensitive = true
}
