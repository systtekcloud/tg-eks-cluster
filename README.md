# AWS Multi-Account EKS Platform with Terragrunt

> **Infrastructure as Code project for multi-account AWS environment**
> Production-ready platform using Terragrunt for DRY configuration and multi-environment orchestration

## 🎯 Overview

This project implements a **secure, multi-account AWS infrastructure** using modern IaC practices:

- **Terragrunt v0.89+** for DRY (Don't Repeat Yourself) infrastructure configuration
- **Multi-account AWS setup** (DEV, PRE, PRO) with IAM role assumption
- **S3 backend** with state isolation per account and environment
- **Modular Terraform code** for reusability and maintainability
- **GitOps-ready** structure for CI/CD integration

### Key Features

✅ **Multi-Account Architecture**: Separate AWS accounts for DEV, PRE, and PRO
✅ **DRY Configuration**: Hierarchical configuration using Terragrunt includes
✅ **State Management**: S3 backends with DynamoDB locking per account
✅ **IAM Role Assumption**: Secure cross-account access with `tfadmin` roles
✅ **Dependency Management**: Automatic dependency resolution between modules
✅ **Scalable Structure**: Easy to add new regions, environments, or components

---

## 📁 Project Structure

```
lab01-eks-cluster/
├── config/                          # Terragrunt configurations
│   ├── root.hcl                     # Root config (backend, provider, common inputs)
│   └── eu-west-1/                   # Regional organization
│       ├── region.hcl               # Region-specific config
│       ├── _env/                    # Shared environment configs
│       │   ├── dev.hcl
│       │   ├── pre.hcl
│       │   └── pro.hcl
│       ├── dev/                     # DEV environment
│       │   ├── account.hcl          # AWS Account ID: 899237616120
│       │   ├── env.hcl              # Environment: dev
│       │   └── vpc/
│       │       └── terragrunt.hcl   # VPC configuration for DEV
│       ├── pre/                     # PRE environment
│       │   ├── account.hcl          # AWS Account ID: 942540403739
│       │   ├── env.hcl              # Environment: pre
│       │   └── vpc/
│       │       └── terragrunt.hcl   # VPC configuration for PRE
│       └── pro/                     # PRO environment
│           ├── account.hcl          # AWS Account ID: 302442772527
│           ├── env.hcl              # Environment: pro
│           └── vpc/
│               └── terragrunt.hcl   # VPC configuration for PRO
│
├── infra/                           # Terraform modules
│   └── vpc/                         # VPC module
│       ├── main.tf                  # Main VPC resources
│       ├── nat.tf                   # NAT Gateway configuration
│       ├── routes.tf                # Route tables
│       ├── variables.tf             # Input variables
│       ├── outputs.tf               # Output values
│       └── versions.tf              # Provider versions
│
├── docs/                            # Documentation
│   ├── TERRAGRUNT_REFERENCE.md      # Complete Terragrunt v0.89+ command guide
│   └── TERRAGRUNT_FUNCTIONS.md      # Terragrunt HCL functions reference
│
├── scripts/                         # Utility scripts
│   └── create-state-buckets-pre-pro.sh  # S3 state bucket creation script
│
├── mise.toml                        # Tool version management (mise)
└── README.md                        # This file
```

---

## 🏗️ Architecture

### Multi-Account Setup

```
┌─────────────────────────────────────────────────────────────┐
│                        User (devops profile)                │
│                    AWS Account: 899237616120                 │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      │ AssumeRole
                      │
        ┌─────────────┼──────────────┐
        │             │              │
        ▼             ▼              ▼
    ┏━━━━━━━━┓   ┏━━━━━━━━┓   ┏━━━━━━━━┓
    ┃  DEV   ┃   ┃  PRE   ┃   ┃  PRO   ┃
    ┃ Account┃   ┃ Account┃   ┃ Account┃
    ┗━━━━━━━━┛   ┗━━━━━━━━┛   ┗━━━━━━━━┛
    899237616120 942540403739 302442772527
        │             │              │
        ▼             ▼              ▼
    tfadmin       tfadmin        tfadmin
     role          role           role
        │             │              │
        ▼             ▼              ▼
    S3 Bucket     S3 Bucket      S3 Bucket
    tfstate-dev   tfstate-pre    tfstate-pro
```

### Configuration Hierarchy

Terragrunt uses a hierarchical configuration model:

```
root.hcl (Global)
    ↓
region.hcl (eu-west-1)
    ↓
account.hcl + env.hcl (dev/pre/pro)
    ↓
terragrunt.hcl (vpc/eks/rds...)
```

Each level inherits and can override configurations from parent levels.

---

## 🚀 Getting Started

### Prerequisites

**Required Tools**:
```bash
# Terraform/OpenTofu
terraform >= 1.5.0

# Terragrunt
terragrunt >= 0.89.0

# AWS CLI
aws-cli >= 2.0.0

# Optional: mise for tool version management
mise >= 2024.x
```

**AWS Configuration**:

1. **AWS Profile**: Configure `devops` profile in `~/.aws/credentials`
   ```ini
   [devops]
   aws_access_key_id = YOUR_ACCESS_KEY
   aws_secret_access_key = YOUR_SECRET_KEY
   ```

2. **IAM Permissions**: The `devops` user must have permission to assume `tfadmin` role:
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [{
       "Effect": "Allow",
       "Action": "sts:AssumeRole",
       "Resource": [
         "arn:aws:iam::899237616120:role/tfadmin",
         "arn:aws:iam::942540403739:role/tfadmin",
         "arn:aws:iam::302442772527:role/tfadmin"
       ]
     }]
   }
   ```

3. **S3 State Buckets**: Create state buckets in each account:
   ```bash
   ./scripts/create-state-buckets-pre-pro.sh
   ```

### Installation with mise

```bash
# Install mise (if not installed)
curl https://mise.run | sh

# Install tools from mise.toml
mise install

# Verify installation
mise current
```

---

## 💻 Usage

### Deploy Single Module (VPC in DEV)

```bash
# Navigate to the module
cd config/eu-west-1/dev/vpc

# Initialize Terragrunt (downloads Terraform modules)
terragrunt init

# Preview changes
terragrunt plan

# Apply changes
terragrunt apply

# View outputs
terragrunt output
```

### Deploy All Modules in One Environment

```bash
# Navigate to the environment
cd config/eu-west-1/dev

# Plan all modules (follows dependency order)
terragrunt plan --all

# Apply all modules
terragrunt apply --all

# Destroy all modules (reverse order)
terragrunt destroy --all
```

### Deploy Specific Module Across All Environments

```bash
# From the root
cd config/eu-west-1

# Deploy VPC in all environments (dev, pre, pro)
terragrunt plan --all \
  --queue-include-dir "*/vpc"

terragrunt apply --all \
  --queue-include-dir "*/vpc"
```

### Deploy Only DEV Environment

```bash
cd config/eu-west-1

# Only DEV modules
terragrunt plan --all \
  --queue-include-dir "dev/*"

terragrunt apply --all \
  --queue-include-dir "dev/*"
```

### Common Commands

```bash
# Validate all configurations
terragrunt validate --all

# View dependency graph
terragrunt dag

# Render final configuration (debugging)
terragrunt render

# List all terragrunt units
terragrunt list

# Clean cache
find . -name ".terragrunt-cache" -type d -exec rm -rf {} +
```

---

## 🔧 Configuration

### AWS Accounts

| Environment | Account ID | Account Name | State Bucket |
|-------------|------------|--------------|--------------|
| **DEV** | 899237616120 | systtekcloud-dev | secure-platform-tfstate-dev |
| **PRE** | 942540403739 | systtekcloud-pre | secure-platform-tfstate-pre |
| **PRO** | 302442772527 | systtekcloud-pro | secure-platform-tfstate-pro |

### Backend Configuration

State is stored in **S3 with DynamoDB locking**:

```hcl
# config/root.hcl
remote_state {
  backend = "s3"
  config = {
    bucket         = "secure-platform-tfstate-${environment}"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = "eu-west-1"
    encrypt        = true
    use_lockfile   = true
    profile        = "devops"

    assume_role = {
      role_arn     = "arn:aws:iam::${account_id}:role/tfadmin"
      session_name = "terragrunt-backend-${environment}"
    }
  }
}
```

**State File Locations**:
- DEV VPC: `s3://secure-platform-tfstate-dev/vpc/terraform.tfstate`
- PRE VPC: `s3://secure-platform-tfstate-pre/vpc/terraform.tfstate`
- PRO VPC: `s3://secure-platform-tfstate-pro/vpc/terraform.tfstate`

### Provider Configuration

AWS provider is auto-generated with role assumption:

```hcl
# Generated _provider.tf in each module
provider "aws" {
  region  = "eu-west-1"
  profile = "devops"

  assume_role {
    role_arn     = "arn:aws:iam::${account_id}:role/tfadmin"
    session_name = "terragrunt-${environment}"
  }

  default_tags {
    tags = {
      Environment = "dev"
      Project     = "secure-platform"
      ManagedBy   = "Terragrunt"
    }
  }
}
```

---

## 📦 Modules

### VPC Module

**Location**: `infra/vpc/`

**Purpose**: Creates a production-ready VPC with public, private, and optional isolated subnets.

**Features**:
- ✅ Multi-AZ architecture
- ✅ Public subnets with Internet Gateway
- ✅ Private subnets with NAT Gateway
- ✅ Configurable NAT strategy (single or per-AZ)
- ✅ Optional isolated subnets (no internet)
- ✅ VPC Flow Logs ready
- ✅ VPC Endpoints ready

**Key Inputs**:

| Variable | Description | Example |
|----------|-------------|---------|
| `environment` | Environment name | `dev`, `pre`, `pro` |
| `project_name` | Project name for naming | `secure-platform` |
| `vpc_cidr` | VPC CIDR block | `10.0.0.0/16` |
| `azs` | Availability zones | `["eu-west-1a", "eu-west-1b"]` |
| `public_subnets` | Public subnet CIDRs | `["10.0.1.0/24", "10.0.2.0/24"]` |
| `private_subnets` | Private subnet CIDRs | `["10.0.11.0/24", "10.0.12.0/24"]` |
| `enable_nat_gateway` | Enable NAT Gateway | `true` |
| `single_nat_gateway` | Single NAT (cost savings) | `true` for dev, `false` for pro |

**Outputs**:

| Output | Description |
|--------|-------------|
| `vpc_id` | VPC ID |
| `vpc_cidr_block` | VPC CIDR block |
| `public_subnet_ids` | List of public subnet IDs |
| `private_subnet_ids` | List of private subnet IDs |
| `nat_gateway_ids` | List of NAT Gateway IDs |
| `internet_gateway_id` | Internet Gateway ID |

**Usage Example**:

```hcl
# config/eu-west-1/dev/vpc/terragrunt.hcl
include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../../infra//vpc"
}

inputs = {
  vpc_cidr = "10.0.0.0/16"
  azs      = ["eu-west-1a", "eu-west-1b"]

  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.11.0/24", "10.0.12.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true  # Cost optimization for dev
}
```

---

## 🔐 Security

### IAM Roles

**tfadmin Role Trust Policy** (in each account):
```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {
      "AWS": "arn:aws:iam::899237616120:root"
    },
    "Action": "sts:AssumeRole"
  }]
}
```

**Permissions**:
- AdministratorAccess (for infrastructure management)
- Can be scoped down based on least privilege principle

### State Encryption

- ✅ S3 buckets have **encryption at rest** (AES256)
- ✅ S3 buckets have **versioning enabled**
- ✅ S3 buckets have **public access blocked**
- ✅ State files contain sensitive data (use encryption)

### Best Practices

1. **Never commit state files** to Git (`.gitignore` configured)
2. **Use IAM roles** for authentication (not access keys in CI/CD)
3. **Enable MFA** for production accounts
4. **Rotate credentials** regularly
5. **Use SOPS** for secrets in Terragrunt configs (see [TERRAGRUNT_FUNCTIONS.md](docs/TERRAGRUNT_FUNCTIONS.md#sops_decrypt_file))

---

## 🧪 Testing

### Validate Configuration

```bash
# Validate Terragrunt config syntax
terragrunt hcl validate

# Validate Terraform code
terragrunt validate --all
```

### Dry Run (Plan)

```bash
# Plan without applying
terragrunt plan --all

# Plan with output to file
terragrunt plan --all --out-dir ./plans
```

### Check Dependencies

```bash
# Generate and view dependency graph
terragrunt dag | dot -Tpng > graph.png
open graph.png
```

---

## 🚨 Troubleshooting

### Common Issues

**Issue**: `Error: No valid credential sources found`

**Solution**:
1. Verify AWS profile is configured: `aws sts get-caller-identity --profile devops`
2. Check if you can assume the role: `aws sts assume-role --role-arn arn:aws:iam::ACCOUNT_ID:role/tfadmin --role-session-name test --profile devops`

**Issue**: `Error: S3 bucket does not exist`

**Solution**: Create state buckets:
```bash
./scripts/create-state-buckets-pre-pro.sh
```

**Issue**: `Error: Unsupported argument "role_arn" in backend`

**Solution**: Use `assume_role` block instead:
```hcl
assume_role = {
  role_arn = "arn:aws:iam::ACCOUNT_ID:role/tfadmin"
}
```

**Issue**: Cache corruption

**Solution**: Clean and reinitialize:
```bash
find . -name ".terragrunt-cache" -type d -exec rm -rf {} +
terragrunt init --source-update
```

### Debug Mode

```bash
# Enable debug logging
export TG_LOG_LEVEL=debug
terragrunt plan --all

# Show full paths in logs
terragrunt --log-show-abs-paths plan

# Disable color for CI/CD
terragrunt --no-color plan --all
```

---

## 📚 Documentation

### Quick References

- **[Terragrunt Commands Guide](docs/TERRAGRUNT_REFERENCE.md)** - Complete guide for Terragrunt v0.89+ CLI commands
  - New `run --all` syntax (replaces deprecated `run-all`)
  - Stack management with `terragrunt stack`
  - Discovery commands (`find`, `list`)
  - Configuration commands (`dag`, `render`, `hcl`)
  - 10+ practical examples
  - CI/CD integration patterns

- **[Terragrunt Functions Guide](docs/TERRAGRUNT_FUNCTIONS.md)** - HCL functions reference
  - File search functions (`find_in_parent_folders()`)
  - File reading functions (`read_terragrunt_config()`, `jsondecode()`, `yamldecode()`)
  - Path functions (`path_relative_to_include()`, `get_terragrunt_dir()`)
  - Dependency management (`dependency` block with mock outputs)
  - AWS functions (`get_aws_account_id()`)
  - Command execution (`run_cmd()`)
  - Environment variables (`get_env()`)
  - 5+ complete end-to-end examples
  - Best practices and patterns

### External Resources

- [Terragrunt Official Docs](https://terragrunt.gruntwork.io/)
- [Terraform AWS Provider Docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS VPC Best Practices](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-security-best-practices.html)

---

## 🛣️ Roadmap

### Phase 1: Foundation ✅
- [x] Multi-account Terragrunt setup
- [x] VPC module with NAT Gateway
- [x] S3 backend with state per account
- [x] IAM role assumption
- [x] Documentation (Terragrunt reference guides)

### Phase 2: EKS Cluster 🔄
- [ ] EKS module with IRSA
- [ ] Node groups (on-demand and spot)
- [ ] Cluster autoscaler
- [ ] VPC CNI configuration
- [ ] EKS addons (CoreDNS, kube-proxy)

### Phase 3: Observability 📋
- [ ] VPC Flow Logs
- [ ] CloudWatch log groups
- [ ] Container Insights
- [ ] Prometheus & Grafana

### Phase 4: GitOps 🔜
- [ ] ArgoCD installation
- [ ] GitHub Actions CI/CD
- [ ] External Secrets Operator
- [ ] Sealed Secrets

### Phase 5: AI/ML Workloads 🚀
- [ ] GPU node groups
- [ ] Jupyter Hub
- [ ] Model serving (KServe)
- [ ] MLflow

---

## 🤝 Contributing

### Development Workflow

1. **Create feature branch**
   ```bash
   git checkout -b feature/add-eks-module
   ```

2. **Make changes and test**
   ```bash
   cd config/eu-west-1/dev/new-module
   terragrunt plan
   ```

3. **Validate changes**
   ```bash
   terragrunt validate --all
   terragrunt hcl validate
   ```

4. **Commit and push**
   ```bash
   git add .
   git commit -m "feat: add EKS module for dev environment"
   git push origin feature/add-eks-module
   ```

### Code Style

- Use **descriptive variable names**
- Add **comments** for complex logic
- Follow **Terraform naming conventions**
- Keep modules **small and focused**
- Document **inputs and outputs**

---

## 📝 License

This project is internal and proprietary. All rights reserved.

---

## 📧 Contact

For questions or support, contact the DevOps team.

---

## 🔖 Version

**Project Version**: 1.0.0
**Terragrunt Version**: v0.89.4
**Terraform Version**: >= 1.5.0
**Last Updated**: 2026-02-25
