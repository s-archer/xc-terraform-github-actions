terraform {
  required_providers {
    volterra = {
      source  = "volterraedge/volterra"
      version = "0.11.9"
    }
    http-full = {
      source = "salrashid123/http-full"
    }
    jq = {
      source  = "massdriver-cloud/jq"
      version = "0.2.0"
    }
  }

  # cloud {
  #   organization = "f5ukse"

  #   workspaces {
  #     name = "xc-terraform-github-actions-waf-exc-rules"
  #   }
  # }
}

provider "volterra" {
  # Configuration options.
  url          = local.api_url
  api_p12_file = var.api_p12_file
}

provider "http-full" {}

provider "jq" {}

resource "volterra_api_credential" "api" {
  name                = format("%s-api-token", var.shortname)
  api_credential_type = "API_TOKEN"

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOF
      #!/bin/bash
      NAME=$(curl --location --request GET 'https://galileo.console.ves.volterra.io/api/web/namespaces/system/api_credentials' \
        --header 'Authorization: APIToken ${self.data}'| jq 'first(.items[] | select (.name | contains("${self.name}")) | .name)') 
      curl --location --request POST 'https://galileo.console.ves.volterra.io/api/web/namespaces/system/revoke/api_credentials' \
        --header 'Authorization: APIToken ${self.data}' \
        --header 'Content-Type: application/json' \
        -d "$(jq -n --arg n "$NAME" '{"name": $n, "namespace": "system" }')"
    EOF
  }
}

data "http" "volterra_get_blocked_by_waf" {
  provider = http-full

  url    = local.api_get_security_events_url
  method = "POST"
  request_headers = {
    Content-Type  = "application/json"
    Authorization = format("APIToken %s", volterra_api_credential.api.data)
  }
  request_body = jsonencode({ aggs : {}, end_time : var.end_timestamp, limit : 0, namespace : var.namespace, query : "{calculated_action=\"block\", authority=\"${var.domain}\",sec_event_type=\"waf_sec_event\"}", scroll : false, sort : "DESCENDING", start_time : var.start_timestamp })
}

data "jq_query" "json_parser" {
  depends_on = [data.http.volterra_get_blocked_by_waf]

  data  = data.http.volterra_get_blocked_by_waf.body
  query = "[.events[] | fromjson | select( .signatures != {} ) | { signature_id: .signatures[].id, method: .method, path: .req_path, host: .authority, params: .req_params } ] | unique"
}

resource "local_file" "waf_exclusion_rules_defined_within_interval" {
  content  = format("variable \"waf_exclusion_rules\" {\n  type = set( object( {\n    signature_id = string\n    method = string\n    host = string\n    path = string\n    params = string\n  } ) )\n  default = %s\n}", data.jq_query.json_parser.result)
  filename = "waf_exclusion_rules_defined_within_interval.tf"
}