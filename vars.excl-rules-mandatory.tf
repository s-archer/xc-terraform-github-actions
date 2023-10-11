variable "waf_exclusion_rules_mandatory" {
  type = set(object({
    signature_id = string
    method       = string
    host         = string
    path         = string
  }))
  default = []
}