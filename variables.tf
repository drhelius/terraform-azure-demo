variable "azure_client_id" {
  type = "string"
}

variable "azure_client_secret" {
  type = "string"
}

variable "azure_location" {
  type    = "string"
  default = "West Europe"
}

variable "azure_subscription_id" {
  type = "string"
}

variable "azure_tenant_id" {
  type = "string"
}

variable "demo_instances" {
  type    = "string"
  default = "2"
}

variable "demo_admin_password" {
  type    = "string"
}
