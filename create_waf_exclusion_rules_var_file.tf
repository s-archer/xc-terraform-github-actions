variable "start_timestamp" {
  type    = string
  default = "1658232000"
}

variable "end_timestamp" {
  type    = string
  default = "1658260800"
}

data "http" "volterra_get_blocked_by_waf" {
  provider = http-full

  url    = var.api_get_security_events_url
  method = "POST"
  request_headers = {
    Content-Type  = "application/json"
    Authorization = format("APIToken %s", var.api_token)
  }

  request_body = jsonencode({ aggs : {}, end_time : var.end_timestamp, limit : 0, namespace : "wsronek-ns1", query : "{authority=\"lloyds-boutique.acmecorp-stage.f5xc.app\",sec_event_type=\"waf_sec_event\"}", scroll : false, sort : "DESCENDING", start_time : var.start_timestamp })
}

data "jq_query" "json_parser" {
  depends_on = [data.http.volterra_get_blocked_by_waf]

  data  = data.http.volterra_get_blocked_by_waf.body
  query = "[.events[] | fromjson | select( .signatures != {} ) | { signature_id: .signatures[].id, method: .method, path: .req_path, host: .authority, params: .req_params } ] | unique"
}

resource "local_file" "signatures" {
  content  = format("variable \"waf_exclusion_rules\" {\n  type = set( object( {\n    name = string\n    signature_id = string\n    method = string\n    host = string\n    path = string\n    params = string\n  } ) )\n  default = %s\n}", data.jq_query.json_parser.result)
  filename = "waf_exclusion_rules_defined_within_interval.tf"
}