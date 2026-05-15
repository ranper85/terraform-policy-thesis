# Terraform Policy-as-Code Governance for Microsoft Azure

This repository contains the implementation for the thesis:

**"Design and Evaluation of a Policy-as-Code Governance Layer for Microsoft Azure Infrastructure using OPA and Conftest in a GitHub Actions CI/CD Pipeline"**

## Overview

The project implements a policy-as-code governance layer that automatically evaluates Terraform plans against nine governance rules before any Azure resources are deployed. The pipeline runs on every push and pull request to the main branch.

## Repository Structure

```
.
├── .github/
│   └── workflows/
│       └── terraform-policy.yml       # GitHub Actions pipeline (4 jobs)
├── policies/
│   ├── compute/
│   │   ├── r01.rego                   # VM size restriction
│   │   └── r08.rego                   # Disk encryption required
│   ├── storage/
│   │   ├── r02.rego                   # Storage tier restriction
│   │   └── r03.rego                   # Public access and HTTPS enforcement
│   ├── networking/
│   │   └── r05.rego                   # SSH/RDP open port restriction
│   ├── identity/
│   │   └── r04.rego                   # IAM role assignment restriction
│   ├── governance/
│   │   ├── r06.rego                   # Approved EU region restriction
│   │   └── r07.rego                   # Required tag enforcement
│   └── database/
│       └── r09.rego                   # SQL firewall restriction
├── terraform/
│   ├── compliant/                     # Passes all 9 policy rules
│   └── non_compliant/                 # Triggers all 9 policy violations
└── test/
    └── fixtures/
        ├── compliant.json             # Test fixture for policy unit testing
        └── non_compliant.json         # Test fixture for policy unit testing
```

## Governance Rules

| Rule | Category   | Description                                      |
|------|------------|--------------------------------------------------|
| R-01 | Compute    | VM size restricted to Standard_B series          |
| R-02 | Storage    | Prohibits Premium storage tier                   |
| R-03 | Storage    | Blocks public blob access, enforces HTTPS        |
| R-04 | Identity   | Denies Owner and Contributor role assignments    |
| R-05 | Networking | Blocks SSH and RDP open to 0.0.0.0/0             |
| R-06 | Governance | Restricts deployment to approved EU regions      |
| R-07 | Governance | Enforces required tags: environment, owner, cost-center |
| R-08 | Compute    | Requires disk encryption on VMs and managed disks |
| R-09 | Database   | Blocks SQL firewall rules open to all IP addresses |

## Pipeline

The GitHub Actions pipeline consists of four jobs:

1. **policy-check-compliant** — runs Conftest against the compliant Terraform plan, must pass
2. **policy-check-non-compliant** — runs Conftest against the non-compliant plan, must detect violations
3. **terraform-apply** — applies the compliant configuration to Azure (push to main only)
4. **terraform-destroy** — destroys the deployed resources with a manual approval gate (push to main only)

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.0
- [Conftest](https://www.conftest.dev) v0.64.0
- Microsoft Azure subscription
- Azure App Registration with OIDC federated credentials configured for GitHub Actions
- Azure Blob Storage backend for Terraform remote state

## Authentication

The pipeline uses OpenID Connect (OIDC) for passwordless authentication to Azure. Three federated credentials are required in the Azure App Registration:

- Entity type: **Branch** (for push events)
- Entity type: **Pull request** (for pull request events)
- Entity type: **Environment** — named `destroy-approval` (for the destroy job)

## Running Locally

```bash
# Install Conftest — see https://www.conftest.dev/install/ for all platforms

# Generate Terraform plan
cd terraform/compliant
terraform init
terraform plan -out=tfplan.binary
terraform show -json tfplan.binary > tfplan.json

# Run policy evaluation
conftest test tfplan.json --policy ../../policies --all-namespaces
```

## Thesis

This repository supports a thesis submitted for the DevOps Engineer 2024 programme at Lernia. The thesis evaluates the effectiveness of policy-as-code governance using OPA and Conftest for Microsoft Azure infrastructure management.
