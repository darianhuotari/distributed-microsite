# distributed-microsite

This is a simple distributed microsite, globally distributed / served via Azure Static Web Apps. 

Required for initial set-up:
- Azure subscription ID
- Ability to create users in an Azure tenant
- Ability to create Github environment variables
- Storage account + container to store terraform state in
- Executing user needs write permissions to above container


Creating a PR triggers a main workflow which:
- runs `tflint` to check format + validate terraform files
- comments pending terraform changes via `terraform plan`
- automatically builds a staging site via the `Azure/static-web-apps-deploy@v1` github action. A comment with a link to the live staging site will be added to PRs.

Notes:

Ensure remote state is properly secured, backed-up, and versioned.
Terraform code lives in the `/infra` directory. Static content is served from the `/static` directory.
Everything is currently deployed into a single RG for simple access. We could break items out into distinct RGs if we wanted granular IAM control on resources.
Whitespace redeploy requires either a terraform destroy which is not currently automated, or removing the resource group + state file.
If we wanted to make this portable, we would want a pre-processor to build the requirements + return them to the client.

To add:

Dev environment / dynamic backends
Custom domain support
Log Analytics
Azure Monitor / Application Insights
Downtime alert
Billing alert
Dashboard
Smoke test
encrypt state in gha