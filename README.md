# distributed-microsite

This is a simple distributed microsite, globally distributed / served via [Azure Static Web Apps.](https://learn.microsoft.com/en-us/azure/static-web-apps/overview) 

Required for initial set-up:
- Azure subscription ID
- Ability to create users in an Azure tenant
- Ability to create Github environment variables
- Storage account + container to store terraform state in
- Executing user needs write permissions to above container

[Set up OIDC to authenticate between GitHub and Azure](https://learn.microsoft.com/en-us/azure/developer/github/connect-from-azure-openid-connect)
Also see: https://github.com/Azure-Samples/terraform-github-actions?tab=readme-ov-file#getting-started


#### General app workflow:

Creating a PR triggers a main workflow using [TF-via-PR](https://github.com/OP5dev/TF-via-PR) which:
- runs `tflint` to check format + validate terraform files
- comments pending terraform changes via `terraform plan`
- automatically builds a staging site via the [Azure/static-web-apps-deploy@v1 GitHub action](https://github.com/Azure/static-web-apps-deploy). A [comment with a link](https://learn.microsoft.com/en-us/azure/static-web-apps/review-publish-pull-requests) to the live staging site will be added to PRs.

#### Local IaC development:

CD into the `infra` directory

`terraform init` using an appropriate backend (i.e. `terraform init -backend-config="backends/development.tfbackend"`)

`terraform plan` using an appropriate backend and tfvars file

Use `terraform fmt` to avoid pipeline failures (this could be made into a pre-commit hook)


#### Local app development:

Set up local development via (local development for Azure Static Web Apps)[https://learn.microsoft.com/en-us/azure/static-web-apps/local-development]

#### Notes:

Ensure remote state is properly secured, backed-up, and versioned.

Terraform code lives in the `/infra` directory. Static content is served from the `/static` directory.

Everything is currently deployed into a single RG for simple access. We could break items out into distinct RGs if we wanted granular IAM control on resources.

Whitespace redeploy requires either a terraform destroy which is not currently automated, or removing the resource group + state file.

If we wanted to make this portable, we would want a pre-processor to build the requirements + return them to the client.

#### Talking points:

Diagram

Make prod deployments a dependency of dev (smoke test dev before deploying to prod?)

Automated destroys

Custom domain support (might help issue where it is hard to tell which stage site belongs to which env)

Custom container for build / deploy, allowing for simpler local development without CI/CD dependencies

Billing alert

Dashboard

encrypt state in gha artifact
