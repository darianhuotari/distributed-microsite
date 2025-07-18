variable "site-name" {
  type        = string
  default     = "micro-site"
  description = "Name of the web app. Will be used to compute dependency names"
}

variable "location" {
  type        = string
  default     = "East US 2"
  description = ""
}

variable "environment_name" {
  description = "The name of the deployment environment (e.g., 'development', 'production')."
  type        = string
}