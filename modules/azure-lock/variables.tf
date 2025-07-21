variable "resource_group_name" {
  description = "The name of the resource group."
  type        = string
}

variable "tag_name" {
  description = "The name of the tag to filter resources."
  type        = string
}

variable "tag_value" {
  description = "The value of the tag to filter resources."
  type        = string
}

variable "lock_level" {
  description = "The level of the lock."
  type        = string
  default     = "ReadOnly"
}
