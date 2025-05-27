resource "volterra_api_credential" "api" {
  name                = format("%s-api-token", var.shortname)
  api_credential_type = "API_TOKEN"
  created_at          = timestamp()
  lifecycle {
    ignore_changes = [
      created_at
    ]
  }
}

data "http" "volterra_get_blocked_by_waf" {
  provider = http-full
  url      = local.api_get_security_events_url
  method   = "POST"
  request_headers = {
    Content-Type  = "application/json"
    Authorization = format("APIToken %s", volterra_api_credential.api.data)
  }
  request_body = jsonencode({ aggs : {}, end_time : var.timestamp_end, limit : 0, namespace : var.namespace, query : "{action=\"block\", authority=\"${var.domain}\",sec_event_type=\"waf_sec_event\"}", scroll : false, sort : "DESCENDING", start_time : var.timestamp_start })
}

data "jq_query" "json_parser" {
  depends_on = [data.http.volterra_get_blocked_by_waf]

  data  = data.http.volterra_get_blocked_by_waf.response_body
  # query = "[.events[] | fromjson | select( .signatures != {} ) | { signature_id: .signatures[].id, method: .method, path: .req_path, host: .authority, context: .signatures[].context } ] | unique"
  query = <<EOT
[
  .events[] 
  | fromjson 
  | select(.signatures != {}) 
  | .signatures[] 
  | {
      signature_id: .id,
      method: .method,
      path: .req_path,
      host: .authority,
      context: (
        if .context | test("^parameter") then "CONTEXT_PARAMETER"
        elif .context | test("^url") then "CONTEXT_URL"
        elif .context | test("^cookie") then "CONTEXT_COOKIE"
        else .context
        end
      ),
      context_name: (
        if .context | test("^parameter \\(") then
          (.context | capture("^parameter \\((?<val>[^\\s)]+)") | .val)
        elif .context | test("^cookie \\(") then
          (.context | capture("^cookie \\((?<val>[^\\s)]+)") | .val)
        else
          empty
        end
      )
    }
] | unique
EOT
}

resource "local_file" "waf_exclusion_rules_defined_within_interval" {
  content  = format("waf_exclusion_rules = %s", data.jq_query.json_parser.result != "null" ? data.jq_query.json_parser.result : "[]")
  filename = "vars.excl-rules.auto.tfvars"
}