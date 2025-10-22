# .github/agents.md

I'm building a Integration with the Observe Platform

This repository demonstrate how to forwards data a single source account so far, from Cloudwatch logs then via Firhose forwards logs to Observe via http endpoint.

Another example is how to forward S3 objects to Observe, for S3 that stores logs, and using a Lambda that is provided by the Observe platform via terraform code we can use (we install their modules)

I have some mock terraform files that creates the S3 and Lambdas for testing to sort of mimic the client existing resources that needs to be integrated with Observe.

Take a look around inside the `iac` folder to understand our project.

For every new request keep in mind that most of the resources will likely be already created

## default

When working with infrastructure code:

- Terraform files live under `iac/`.
- Review `iac/networking.tf` and `iac/main.tf` for examples of structure.
- Follow our tagging and locals conventions.
- As we leverage provider `default_tags` you only need to create. the `Name` tag for new resources
- For complex tasks, prefer creating a game plan before the implementation
- Once you finish a task, run the terraform commands to init, validate and run the plan
- Always run the plan with `terraform plan -out=tfplan | tee tfplan.log` so you can see the tfplan.log files in the `iac` folder in case it takes longer to complete
- Never run terraform apply
- Use the terraform mcp and the aws documentation as much as possible
