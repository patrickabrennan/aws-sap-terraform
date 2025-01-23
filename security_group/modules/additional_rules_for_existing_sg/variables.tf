variable "environment" {
  description = "Environment being built. DEV, QA or PRD"
  type        = string
}

variable "sgs_to_allow" {
  description = "List of Security Groups to add rules to"
  type        = list(string)
}

variable "sg_source" {
  type        = string
  description = "The SG used as source"
}
