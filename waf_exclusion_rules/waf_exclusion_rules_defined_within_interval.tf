variable "waf_exclusion_rules" {
  type = set( object( {
    signature_id = string
    method = string
    host = string
    path = string
 } ) )
  default = [{"host":"juice.gal.volcloud.net","method":"GET","path":"/socket.io/","signature_id":"200004025"}]
}