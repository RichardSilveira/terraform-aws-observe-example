# .github/agents.md

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
