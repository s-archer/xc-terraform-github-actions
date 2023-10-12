variable "waf_exclusion_rules_mandatory" {
  type = set(object({
    signature_id = string
    method       = string
    host         = string
    path         = string
  }))
  default = [{"host":"juiceshop-waf.volt.archf5.com","method":"GET","path":"/etc/passwd","signature_id":"200010468"},{"host":"juiceshop-waf.volt.archf5.com","method":"GET","path":"/rest/products/1/reviews","signature_id":"200002053"}]
}