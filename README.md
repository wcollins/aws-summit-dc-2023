![Session](./session.png)

## **DEV203:** Cloud-grade network segmentation using AWS Transit Gateway & Terraform
- **Level:** 200 - Intermediate
- **Area of Interest:** Network & Infrastructure Security
- **Role:** Developer, Engineer, Architect
- **Topic:** Cloud Operations, Networking

### Overview
This repo contains the _slide deck_ and [Terraform](https://www.terraform.io/) used at the [2023's DC Summit](https://aws.amazon.com/events/summits/washington-dc/).

### Provisioning Infrastructure
```hcl
terraform init
terraform plan -out=tfplan
terraform apply "tfplan"
```

### Destroying Infrastructure
```hcl
terraform destroy
```