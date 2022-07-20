locals {
  api_url = format("https://%s.%s/api", var.tenant, var.console_url)
  api_get_security_events_url = format("https://%s.%s/api/data/namespaces/%s/app_security/events", var.tenant, var.console_url, var.namespace)
}

variable "console_url" {
  type    = string
  default = ""
}

variable "api_p12_file" {
  type    = string
  default = ""
}

variable "tenant" {
  type    = string
  default = ""
}

variable "namespace" {
  type    = string
  default = ""
}

variable "start_timestamp" {
  type    = string
  default = ""
}

variable "end_timestamp" {
  type    = string
  default = ""
}

variable "shortname" {
  type    = string
  default = ""
}

variable "domain" {
  type    = string
  default = ""
}