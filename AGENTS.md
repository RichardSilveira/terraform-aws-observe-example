# .github/agents.md

This repository demonstrates how to forward AWS data into Observe Platform leveraging Terraform from multiple sources:

- Cloudwatch Logs: via subscription filter to Firehose, then via http forward the logs to Observe.

- S3 Simplified version:  via S3 bucket event ingestion integrated with eventbridge which the "Observe Lambda Forwarder" as a target (Lambda created leveraging Observe Terraform modules)

- S3 Cost-optimized version also know as "Filedrop": Similar to the Simplified version, but leveraging the "filedrop" Observe approach which creates a different Lambda and puts some Dead Letter Queues, plus leverage batch processing for cost-optimization and forward S3 objects over aws network backbone directly the to S3 bucket access point in the Observe AWS Account.

- Cross Account scenario for CloudWatch Logs: via subscription filter to the CW Log Destionation in the destionation account that integrates with Firehose also in the destionation account to forward logs to Observe via http.

It also contains mock terraform files that creates the S3 and Lambdas for testing to sort of mimic the client existing resources that needs to be integrated with Observe.

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
