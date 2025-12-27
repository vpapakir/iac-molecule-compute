# iac-molecule-compute

A cloud-agnostic Terraform molecule for provisioning compute nodes (virtual machines) across multiple cloud providers as part of an atom-molecule-template infrastructure architecture.

## Traffic Light System

This repository implements a **traffic light system** for CI/CD pipeline control using structured commit messages. This ensures only the intended CI tool runs for each commit, preventing pipeline conflicts and resource waste.

### Commit Message Convention

All commit messages must follow the following format:
```
[repo] [cloud] [ci-tool] [action] <description>
```

**Components:**
- `[repo]`: Repository platform - `[github]` (future: `[gitlab]`, `[bitbucket]`)
- `[cloud]`: Target cloud provider - `[azure]`, `[aws]`, `[civo]`, `[oci]`
- `[ci-tool]`: CI/CD platform - `[ado]`, `[gh_actions]`, `[aws_pipeline]`, `[oci_pipeline]`
- `[action]`: Pipeline action - `[build]`, `[release]`

**Examples:**
```bash
# Build and validate Azure module using Azure DevOps
git commit -m "[github] [azure] [ado] [build] fix: update VM sizes"

# Build and validate AWS module using GitHub Actions
git commit -m "[github] [aws] [gh_actions] [build] feat: add new instance types"

# Create release PR for Civo module using AWS CodePipeline
git commit -m "[github] [civo] [aws_pipeline] [release] feat: ready for release"
```

### Pipeline Actions

#### Build Action `[build]`
- **Purpose**: Validate and test infrastructure code
- **Execution**: Only runs in the specified CI tool
- **Steps**:
  1. Terraform init, plan, validate on examples
  2. Terraform fmt check, validate on modules
  3. Security scanning with Checkov
- **Output**: Validation results, no module publishing

#### Release Action `[release]`
- **Purpose**: Create release pull request
- **Execution**: Only runs in the specified CI tool
- **Steps**:
  1. All build validation steps
  2. Create automated PR to main branch
- **Output**: Pull request ready for review

### PR Approval and Publishing

When approving a release PR, use this format:
```
[APPROVED] [VERSION_BUMP] [ci-tool] <description>
```

**Components:**
- `[APPROVED]`: Approval decision
- `[VERSION_BUMP]`: `[MAJOR]`, `[MINOR]`, or `[PATCH]`
- `[ci-tool]`: Which CI tool should publish the module

**Examples:**
```bash
# Approve with patch version bump via Azure DevOps
"[APPROVED] [PATCH] [ado] looks good to go"

# Approve with minor version bump via GitHub Actions
"[APPROVED] [MINOR] [gh_actions] new features added"
```

### Pipeline Execution Matrix

| Commit Message | Azure DevOps | GitHub Actions | AWS CodePipeline | OCI DevOps |
|---|---|---|---|---|
| `[github] [azure] [ado] [build]` | ✅ Run | ❌ Skip | ❌ Skip | ❌ Skip |
| `[github] [aws] [gh_actions] [release]` | ❌ Skip | ✅ Run | ❌ Skip | ❌ Skip |
| `[github] [civo] [aws_pipeline] [build]` | ❌ Skip | ❌ Skip | ✅ Run | ❌ Skip |
| `[github] [oci] [oci_pipeline] [release]` | ❌ Skip | ❌ Skip | ❌ Skip | ✅ Run |

### Benefits

1. **No Pipeline Conflicts**: Only one CI tool runs per commit
2. **Resource Efficiency**: Eliminates redundant pipeline executions
3. **Clear Intent**: Commit message explicitly states which tool should run
4. **Flexible Publishing**: Choose which CI tool publishes the final module
5. **Multi-Cloud Support**: Test different cloud providers in different CI environments

## Architecture Overview

This repository follows the **atom-molecule-template** design pattern:

- **Atoms**: Individual infrastructure components (VNet, subnet, disk, etc.)
- **Molecules**: Compositions of atoms that create functional units (this compute molecule)
- **Templates**: Complete application stacks that consume molecules

## Design Philosophy

### Cloud-Agnostic Interface
Developers interact with infrastructure through YAML parameter files, abstracting away cloud-specific details. The same YAML configuration can provision resources across different cloud providers.

### Pipeline-Driven Workflow
1. Developers define infrastructure requirements in YAML
2. Push changes to repository with appropriate commit message prefixes
3. Automated pipelines execute:
   - Terraform plan and validation
   - Code linting and security scanning
   - Pull request creation (with `[release]` flag)
   - Module publishing to Terraform Cloud (on main/master)

### Multi-Platform CI/CD
- **Azure DevOps** (`.azure/` directory) - Gold standard implementation
- **GitHub Actions** (`.github/workflows/` directory) - Mirrors Azure DevOps functionality
- **AWS CodePipeline** (`buildspec.yml`) - Manual setup with build specification
- **Oracle Cloud DevOps** (`.oci/` directory) - OCI DevOps build specification

All four platforms execute identical plan-test-release workflows with intelligent commit message filtering, conditional PR creation, and reviewer-controlled semantic versioning.

## Current Implementation

### Supported Cloud Providers

#### Azure (`iac/terraform/azure/`)
- **Resource**: Azure Virtual Machine (Linux/Windows)
- **Networking**: VNet, Subnet, NSG, Public IP (optional)
- **Features**: SSH key authentication, configurable VM sizes, custom images
- **State**: Terraform Cloud workspace (`compute-azure-dev`)
- **Outputs**: VM details, networking info, SSH connection commands

#### AWS (`iac/terraform/aws/`)
- **Resource**: EC2 Instance
- **Networking**: VPC, Subnet, Security Group, Internet Gateway (optional)
- **Features**: Key pair management, configurable instance types, custom AMIs
- **State**: Terraform Cloud workspace (`compute-aws-dev`)
- **Outputs**: Instance details, networking info, SSH connection commands

#### Civo (`iac/terraform/civo/`)
- **Resource**: Civo compute instance
- **Networking**: Network, firewall with custom rules
- **Features**: SSH key management, configurable sizes, user data
- **State**: Terraform Cloud workspace (`compute-civo-dev`)

#### OCI (`iac/terraform/oci/`)
- **Resource**: OCI compute instance (flexible shapes supported)
- **Networking**: VCN, subnet, security list, internet gateway
- **Features**: SSH key management, configurable shapes, custom images
- **State**: Terraform Cloud workspace (`compute-oci-dev`)

### Module Structure
Each cloud provider module includes:
- `main.tf` - Core resource definitions
- `variables.tf` - Input parameters
- `outputs.tf` - Exposed values for consumption
- `backend.tf` - Terraform Cloud configuration
- `versions.tf` - Terraform version constraints
- `terraform.tfvars.example` - Configuration examples

### YAML-Driven Configuration
Cloud-agnostic YAML interface for developers:

```yaml
compute:
  name: "myapp-dev"
  provider: "azure"  # azure, aws, civo, oci
  region: "eastus"
  size: "small"      # small, medium, large, xlarge
  os:
    type: "linux"     # linux, windows
    image: "ubuntu-22.04"
  networking:
    public_ip: true
    allow_ssh: true
  storage:
    type: "standard"   # standard, premium, ssd
    size_gb: 20
    encrypted: true
  tags:
    Environment: "dev"
    Project: "myapp"
```

## Usage

### Module Publication
Modules are automatically published to Terraform Cloud and referenced by URI:

```hcl
module "compute" {
  source  = "app.terraform.io/vpapakir/compute/azure"
  version = "~> 1.0"
  
  name_prefix         = "myapp-dev"
  resource_group_name = "rg-myapp-dev"
  location           = "East US"
  vm_size            = "Standard_B2s"
  os_type            = "linux"
  ssh_public_key     = var.ssh_public_key
}
```

### Release Workflow

#### 1. Development
```bash
git commit -m "[ado] feat: add new compute features"
git push origin feature-branch
```
- Runs Commit Check → Plan → Test stages
- Validates module functionality across all platforms

#### 2. Release Intent
```bash
git commit -m "[ado][release] feat: ready for release"
git push origin feature-branch
```
- Runs Commit Check → Plan → Test → **Create PR** stages
- Automatically creates PR to main/master
- Requires team review and approval with version control

#### 3. Automatic Publication
- Reviewer approves PR with version message (e.g., "APPROVED MINOR")
- PR merge triggers pipeline on main/master
- Runs Commit Check → Plan → Test → **Release** stages
- Publishes versioned module to Terraform Cloud
- Creates git tag with semantic version

### Intelligent Semantic Versioning

The release pipeline implements reviewer-controlled semantic versioning:

**Version Determination Logic:**
- Parses git tags to find current version (starts with 0.0.1 if no tags exist)
- Analyzes PR merge commit messages for approval keywords
- Increments version based on reviewer approval message:
  - `APPROVED MAJOR` → Major version bump (1.0.0 → 2.0.0)
  - `APPROVED MINOR` → Minor version bump (1.0.0 → 1.1.0)
  - `APPROVED PATCH` or default → Patch version bump (1.0.0 → 1.0.1)

**Example Workflow:**
1. Developer creates PR with `[release]` flag
2. Automated PR is created by pipeline
3. Reviewer approves with message: "APPROVED MINOR - new cloud provider support"
4. PR merge triggers release pipeline
5. Pipeline creates version 1.1.0 and publishes to Terraform Cloud

## Pipeline Configuration

### Template-Based Architecture
Pipelines use reusable templates for maintainability:

```
.azure/
├── pipeline.yml              # Main pipeline orchestration
└── templates/
    ├── stages/
    │   ├── plan.yml             # Terraform planning stage
    │   ├── test.yml             # Linting and security scanning
    │   ├── create-pr.yml        # Pull request creation
    │   └── release.yml          # Module publishing
    └── jobs/
        ├── terraform-plan.yml   # Plan job template
        ├── terraform-test.yml   # Test job template
        ├── create-pr.yml        # PR creation job
        └── terraform-release.yml # Release job template
```

### Commit Message-Based Pipeline Triggering
Control which CI/CD platform executes using commit message prefixes:

| Commit Message | Platform | Target Provider | Modules Validated | Use Case |
|---|---|---|---|---|
| `[ado]` | Azure DevOps | Azure | Azure only | Azure-specific development |
| `[gh] [azure]` | GitHub Actions | Azure | Azure only | Cross-platform Azure testing |
| `[gh] [amazon]` | GitHub Actions | AWS | AWS only | Cross-platform AWS testing |
| `[gh] [civo]` | GitHub Actions | Civo | Civo only | Cross-platform Civo testing |
| `[gh] [oci]` | GitHub Actions | OCI | OCI only | Cross-platform OCI testing |
| `[gh]` | GitHub Actions | All | All modules | Multi-cloud validation |
| `[aws]` | AWS CodePipeline | AWS | AWS only | AWS-specific development |
| `[oci]` | Oracle Cloud DevOps | OCI | OCI only | OCI-specific development |
| No prefix | Azure DevOps (default) | All | All modules | General development, Civo work |

**Release Workflow Examples:**
```bash
# Platform-specific releases
git commit -m "[ado] [release] feat: azure vm improvements"     # Azure DevOps → PR
git commit -m "[aws] [release] feat: ec2 security updates"       # AWS CodePipeline → PR
git commit -m "[gh] [azure] [release] feat: test azure changes" # GitHub Actions → PR

# Multi-cloud releases
git commit -m "[release] feat: cross-cloud networking updates"   # Azure DevOps → PR (default)
```

### Pipeline Stages

#### Commit Check Stage
- Parses commit messages to determine which CI/CD platform should execute
- Sets conditional variables for PR creation and release workflows
- Validates commit message format and pipeline routing

#### Plan Stage
- Configures Terraform Cloud authentication
- Tests module consumption patterns using example configurations
- Validates Terraform plans across all cloud providers
- Ensures modules can be consumed correctly

#### Test Stage
- Installs security scanning tools (Checkov)
- Runs `terraform fmt -check` and `terraform validate` across all modules
- Performs security vulnerability scanning on all cloud provider modules
- Validates code quality and compliance standards

#### Create PR Stage (Conditional)
- **Trigger**: `[release]` in commit message + not on main/master branch
- Creates pull request to main/master branch using GitHub CLI
- Includes automated PR description with change summary
- Sets up approval workflow for release with version control

#### Release Stage (Conditional)
- **Trigger**: Pipeline runs on main/master branch
- Implements intelligent semantic versioning based on PR approval messages
- Parses reviewer approval messages (APPROVED MAJOR/MINOR/PATCH)
- Creates git tags with proper SemVer formatting
- Publishes modules to Terraform Cloud registry

### Required Variable Groups

#### Azure DevOps Variable Groups

**`terraform` Variable Group**
- `apiKey` - Terraform Cloud API token

**`shared` Variable Group**
- `ARM_CLIENT_ID` - Azure Service Principal ID
- `ARM_CLIENT_SECRET` - Azure Service Principal Secret
- `ARM_SUBSCRIPTION_ID` - Azure Subscription ID
- `ARM_TENANT_ID` - Azure Tenant ID
- `GITHUB_TOKEN` - GitHub Personal Access Token (for PR creation)

#### GitHub Actions Secrets
- `TF_CLOUD_TOKEN` - Terraform Cloud API token
- `GITHUB_TOKEN` - Automatically provided by GitHub Actions

#### AWS CodePipeline Setup

**Manual Setup Required:**
1. **Create CodePipeline** manually in AWS Console
2. **Configure Source**: GitHub (Version 2) with webhook events
3. **Create CodeBuild Project** with:
   - **Source**: Use buildspec file (`buildspec.yml`)
   - **Environment**: Standard Linux image
   - **Service Role**: Auto-created role

**Required Environment Variables:**
- `TF_CLOUD_TOKEN` - Terraform Cloud API token (Plaintext)
- `GITHUB_TOKEN` - GitHub Personal Access Token (for PR creation)

**Required IAM Permissions:**
Add to CodeBuild service role (`codebuild-{project-name}-service-role`):
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeAvailabilityZones",
                "ec2:DescribeImages",
                "ec2:DescribeVpcs",
                "ec2:DescribeSubnets"
            ],
            "Resource": "*"
        }
    ]
}
```

**Pipeline Execution:**
- Uses `buildspec.yml` for complete plan-test-release workflow
- Includes Terraform planning, security scanning with Checkov
- Supports PR creation and intelligent versioning
- Fails pipeline on security violations
#### Oracle Cloud DevOps Parameters
- `TF_CLOUD_TOKEN` - Terraform Cloud API token
- `GITHUB_TOKEN` - GitHub Personal Access Token
- Build pipeline environment variables for OCI authentication

## Future Evolution

### Centralized Pipeline Templates
Pipeline templates have been moved to the centralized `iac-pipeline-templates` repository:
- **Template Repository**: https://github.com/vpapakir/iac-pipeline-templates
- **Current Version**: `v0.0.3`
- **Reusable Across**: All infrastructure modules (atoms, molecules, templates)
- **Consistent Workflows**: Same plan-test-release logic organization-wide

### Atomic Decomposition
Over time, individual components will be extracted into separate atoms:
- **VNet Atom**: Virtual network provisioning
- **Subnet Atom**: Subnet management
- **Disk Atom**: Storage provisioning
- **Alert Rules Atom**: Monitoring configuration

The compute molecule will then compose these atoms rather than managing resources directly.

### Pipeline Template Repository
Templates are now centralized in the `iac-pipeline-templates` repository:
- Shared across all infrastructure repositories
- Versioned template releases (`v0.0.3`)
- Consistent CI/CD patterns organization-wide
- Reduced code duplication and maintenance overhead

### Additional Features
- **Multi-environment support** - Dev, staging, production configurations
- **Cost optimization** - Automated resource sizing recommendations
- **Compliance scanning** - Policy-as-code integration
- **Monitoring integration** - Automatic alerting setup
- **CloudFormation Support** - Infrastructure-as-Code pipeline deployment for AWS

## Repository Structure

```
iac-molecule-compute/
├── .azure/                    # Azure DevOps pipeline definitions
│   └── pipeline.yml           # Main pipeline using centralized templates
├── .github/                   # GitHub Actions workflows
│   └── workflows/
│       └── plan-test-release.yml
├── .oci/                      # Oracle Cloud DevOps pipeline
│   └── build_spec.yaml        # OCI DevOps build specification
```
├── .oci/                      # Oracle Cloud DevOps pipeline
│   └── build_spec.yaml        # OCI DevOps build specification
├── buildspec.yml              # AWS CodeBuild specification
├── examples/                  # Pipeline testing examples
│   ├── azure-example/         # Azure module consumption example
│   ├── aws-example/           # AWS module consumption example
│   ├── compute-config.yaml    # YAML interface example
│   ├── mappings.yaml          # Cloud provider mappings
│   └── multi-env-config.yaml  # Multi-environment example
├── iac/
│   ├── ansible/              # Ansible playbooks (future)
│   ├── bicep/                # Azure Bicep templates (future)
│   ├── scripts/              # Utility scripts
│   │   ├── bash/
│   │   └── powershell/
│   └── terraform/            # Terraform modules
│       ├── aws/              # AWS EC2 module
│       ├── azure/            # Azure VM module
│       ├── civo/             # Civo instance module
│       └── oci/              # OCI compute module
├── .gitignore
├── LICENSE
└── README.md
```

## Contributing

This molecule implements a **traffic light system** for clean CI/CD pipeline control. When contributing:

1. **Follow commit message convention** - Use `[repo] [cloud] [ci-tool] [action]` format
2. **Test in single CI tool** - Only your specified tool will run
3. **Use build for development** - Validate changes with `[build]` action
4. **Use release for PR creation** - Create PRs with `[release]` action  
5. **Control module publishing** - Choose CI tool in PR approval message
6. **Maintain cloud-agnostic interfaces** - Keep YAML schema consistent
7. **Update documentation** - Ensure README reflects any changes

### Quick Reference

```bash
# Development testing
git commit -m "[github] [aws] [gh_actions] [build] fix: update security groups"

# Ready for release
git commit -m "[github] [aws] [gh_actions] [release] feat: new compute features"

# PR approval (in GitHub PR comment)
"[APPROVED] [MINOR] [gh_actions] new features look good"
```

This system eliminates pipeline conflicts and ensures clean, predictable CI/CD execution across all supported platforms.

### Development Workflow

1. **Create feature branch** from main
2. **Make infrastructure changes** to modules or examples
3. **Test with build commits**:
   ```bash
   git commit -m "[github] [azure] [ado] [build] fix: update VM configuration"
   git push origin feature-branch
   ```
4. **Validate in target CI tool** - only specified tool runs
5. **Create release when ready**:
   ```bash
   git commit -m "[github] [azure] [ado] [release] feat: ready for release"
   git push origin feature-branch
   ```
6. **Review automated PR** created by CI tool
7. **Approve with version control**:
   ```bash
   # In PR approval message
   "[APPROVED] [PATCH] [ado] changes look good"
   ```
8. **Merge PR** - triggers module publishing in approved CI tool

### Pipeline Configuration

Each CI tool has identical functionality but different trigger conditions:

#### Azure DevOps (`.azure/pipeline.yml`)
- **Triggers on**: `[ado]` in commit message
- **Variable Groups**: `terraform` (TF_CLOUD_TOKEN), `shared` (GITHUB_TOKEN)
- **Stages**: CommitCheck → Build → CreatePR → Publish

#### GitHub Actions (`.github/workflows/pipeline.yml`)
- **Triggers on**: `[gh_actions]` in commit message  
- **Secrets**: `TF_CLOUD_TOKEN`, `GITHUB_TOKEN` (auto-provided)
- **Jobs**: commit-check → build → create-pr → publish

#### AWS CodePipeline (`buildspec.yml`)
- **Triggers on**: `[aws_pipeline]` in commit message
- **Environment Variables**: `TF_CLOUD_TOKEN`, `GITHUB_TOKEN`
- **Phases**: install → pre_build → build → post_build

#### OCI DevOps (`.oci/build_spec.yaml`)
- **Triggers on**: `[oci_pipeline]` in commit message
- **Parameters**: `TF_CLOUD_TOKEN`, `GITHUB_TOKEN`
- **Steps**: Parse → Install → Validate → CreatePR → Publish

## License

See [LICENSE](LICENSE) file for details.