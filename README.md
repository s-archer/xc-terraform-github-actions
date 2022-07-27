# F5 Distributed Cloud Terraform Github Actions

**see https://f5.com/cloud for product details**

The concept for this project is to show how a WAF policy can be automatically refined within a closed test environment using F5 Distributed Cloud.  

The scenario is that a WAF is deployed into a secure test environment and 'good' traffic sent to the app, through the WAF to ensure the WAF does not inadvertently block.  If the WAF blocks anything, it is considered to be false-positive and is likely to adversely affect the function of the application. A decision must be made between 'speed' (loosen the WAF policy by creating an exception rule) or 'security' (request that the application is remediated).

If the choice is 'speed' then this project shows how a Github Actions Terraform workflow can run tests through a WAF, get the security events generated during the tests, and automatically create WAF exception rules.  There is also the option to move rules created automatically into a mandatory list, so that they are permenantly stored within the configuration. 

## How to use this project:

- clone the repo
- update the `vars.auto-tfvars` file to suit your environment
- make a code change
- `git add .`
- `git commit -m "my message"`
- `git push`   
    - `git push` causes the Github Actions workflow to trigger.

## Example workflow 1

**- during first run:**
    - create a LB & WAF on F5 Distributed Cloud Regional Edges, with an Origin pointing at another public site.
    - result is LB & WAF with no exceptions

**- during second run:**
    - record start timestamp, run tests against app, record end timestamp
    - the tests intentionally generate two WAF security violations
    - get security violations between timestamps, use the violations to generate two automatic WAF exception rules and apply them to the LB
    - result is LB & WAF with two automatically generated exception rules

**- during third run:**
    - record start timestamp, run tests against app, record end timestamp
    - this time, the tests do not trigger WAF security events, because exception rules exist.
    - result is functioning application, with no WAF false-positives

Remove LB, Origin and WAF in XC to reset the workflow.

## Example Workflow 2

**- during first run:**
    - create a LB & WAF on F5 Distributed Cloud Regional Edges, with an Origin pointing at another public site.

**- before second run:**
    - comment out one of the curl tests in `./.github/workflows/terraform.yml`

**- during second run:**
    - record start timestamp, run tests against app, record end timestamp
    - the test intentionally generates 1 x WAF security violation
    - get security violations between timestamps, use the violations to generate 1 x automatic WAF exception rule and apply to the LB
    - result is LB & WAF with one automatically generated exception rule

**- before third run:**
    - uncomment the curl test you previously commented out, in ./.github/workflows/terraform.yml
    - remove the content inside the braces `[]` in `waf_exclusion_rules = []` in the `vars.excl-rules.auto.tfvars` file and paste inside the braces `[]` in ` default = []` in the `vars.excl-rules-mandatory.tf` file.  This becomes a madatory rule that will persist in the configuration.

**- during third run:**
    - record start timestamp, run tests against app, record end timestamp
    - one test (that you just uncommented) intentionally generates 1 x new WAF security violation.  The other test does not generate WAF violation because there is now a mandatory WAF exception rule for that.
    - get security violations between timestamps, use the violations to generate 1 x automatic WAF exception rule and apply to the LB
    - result is WAF with one mandatory and one automatic exception rule.

Remove LB, Origin and WAF in XC to reset the workflow.