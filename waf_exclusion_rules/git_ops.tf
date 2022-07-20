resource "gitops_checkout" "updates_checkout" {
    path = "./"
    branch = "updates"
}

resource "gitops_file" "waf_file" {
  checkout = gitops_checkout.updates_checkout.id
  path = "waf_exclusion_rules_defined_within_interval_git.tf"
  contents  = format("variable \"waf_exclusion_rules\" {\n  type = set( object( {\n    signature_id = string\n    method = string\n    host = string\n    path = string\n    params = string\n  } ) )\n  default = %s\n}", data.jq_query.json_parser.result)
}

resource "gitops_commit" "updates_commit" {
  commit_message = "Created by terraform gitops_commit"
  handles = [gitops_file.waf_file.id]
}