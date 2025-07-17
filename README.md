# distributed-microsite

This is a simple distributed microsite, globally distributed / served via Azure Static Web Apps. 

Required for initial set-up:
- Azure subscription ID
- Ability to create users in an Azure tenant
- Ability to create Github environment variables
- Storage account + container to store terraform state in
- Executing user needs write permissions to above container


Creating a PR triggers a main workflow which lists pending terraform changes via `terraform plan` and also automatically builds a staging site via the `Azure/static-web-apps-deploy@v1` github action. A comment with a link to the live staging site will be added to PRs.

Notes:

Terraform code lives in the `/infra` directory. Static content is served from the `/static` directory. 

