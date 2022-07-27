# xc-terraform-github-actions

In order to use this project:

- clone the repo
- update the `vars.auto-tfvars` file to suit your environment
- make a code change
- `git add .`
- `git commit -m "my message"`
- `git push`   
    - `git push` causes the Github Actions workflow to trigger.

The workflow will:

- during first run:
    - create a LB & WAF on F5 Distributed Cloud Regional Edges, with an Origin pointing at another public site.

- during second run:
    - record start timestamp, run tests against app, record end timestamp
    - the tests intentionally generate 2 x WAF security violations
    - get security violations between timestamps, use the violations to generate WAF exception rules and apply them to the LB (2 automatically created rules)

- during third run:
    - record start timestamp, run tests against app, record end timestamp
    - this time, the tests do not trigger WAF security events, because exception rules exist.


Alternate workflow:

- during first run:
    - create a LB & WAF on F5 Distributed Cloud Regional Edges, with an Origin pointing at another public site.

- before second run:
    - comment out one of the curl tests in `./.github/workflows/terraform.yml`

- during second run:
    - record start timestamp, run tests against app, record end timestamp
    - the test intentionally generates 1 x WAF security violation
    - get security violations between timestamps, use the violations to generate WAF exception rule and apply to the LB (1 automatically created rule)

- before third run:
    - uncomment the curl test you previously commented out, in ./.github/workflows/terraform.yml
    - remove the content inside the braces `[ ]` in `waf_exclusion_rules = []` in the `vars.excl-rules.auto.tfvars` file and paste into the braces `[ ]` in ` default = []` in the `vars.excl-rules-mandatory.tf` file.  This becomes a madatory rule that will persist in the configuration.

- during third run:
    - record start timestamp, run tests against app, record end timestamp
    - one test (that you just uncommented) intentionally generates 1 x new WAF security violation.  The other test 
    - get security violations between timestamps, use the violations to generate WAF exception rule and apply to the LB (1 automatically created rule)
