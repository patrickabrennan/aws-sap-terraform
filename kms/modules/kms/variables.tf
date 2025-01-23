variable "aws_region" {
  description = "Region where to run this TF in"
  type        = string
}

variable "environment" {
  description = "Environment to be used for this run"
  type        = string
}

variable "target_service" {
  description = "Service that this KMS is going to be used for"
  type        = string
}

variable "alias_name" {
  description = "Alias to apply to the key"
  type        = string
}
