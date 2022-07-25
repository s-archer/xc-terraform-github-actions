variable "mandatory_waf_exclusion_rules" {
  type = set( object( {
    signature_id = string
    method = string
    host = string
    path = string
  } ) )
  default = []
}
