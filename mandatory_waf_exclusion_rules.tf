variable "mandatory_waf_exclusion_rules" {
  type = set( object( {
    signature_id = string
    method = string
    host = string
    path = string
  } ) )
  default = [{"host":"juice.gal.volterra.link","method":"GET","path":"/rest/products/1/reviews","signature_id":"200002053"}]
}
