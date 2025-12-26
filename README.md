# iac-molecule-compute

A cloud-agnostic Terraform molecule for provisioning compute nodes (virtual machines) across multiple cloud providers as part of an atom-molecule-template infrastructure architecture.

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
- **AWS CodePipeline** (`.aws/` directory) - CloudFormation-based pipeline
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

- `[ado]` - Triggers Azure DevOps pipeline
- `[gh]` - Triggers GitHub Actions pipeline  
- `[aws]` - Triggers AWS CodePipeline
- `[oci]` - Triggers Oracle Cloud DevOps pipeline
- `[release]` - Initiates release workflow (creates PR or publishes)
- No prefix - Defaults to Azure DevOps pipeline

**Examples:**
```bash
git commit -m "fix: update terraform module"           # Runs Azure DevOps (default)
git commit -m "[gh] feat: add new feature"             # Runs GitHub Actions only
git commit -m "[aws] chore: update pipeline"           # Runs AWS CodePipeline only
git commit -m "[oci] docs: update documentation"       # Runs Oracle Cloud DevOps only
git commit -m "[ado][release] docs: update README"     # Runs Azure DevOps + Release workflow
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

#### AWS CodePipeline Parameters
- `TerraformCloudToken` - Terraform Cloud API token
- `GitHubToken` - GitHub Personal Access Token
- `GitHubOwner` - GitHub repository owner
- `GitHubRepo` - GitHub repository name
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

## Repository Structure

```
iac-molecule-compute/
├── .aws/                      # AWS CodePipeline infrastructure
│   ├── pipeline-complete.yaml # Complete CloudFormation template
│   └── deploy-pipeline.sh     # Deployment script
├── .azure/                    # Azure DevOps pipeline definitions
│   └── pipeline.yml           # Main pipeline using centralized templates
├── .github/                   # GitHub Actions workflows
│   └── workflows/
│       └── plan-test-release.yml
├── .oci/                      # Oracle Cloud DevOps pipeline
│   └── build_spec.yaml        # OCI DevOps build specification
```
.oci/                      # Oracle Cloud DevOps pipeline
│   └── build_spec.yaml    # OCI DevOps build specification
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

This molecule is designed for reusability across teams and projects. When contributing:

1. **Follow commit message conventions** - Use appropriate prefixes for pipeline control
2. **Use release workflow** - Add `[release]` flag when ready for publication
3. **Maintain cloud-agnostic interfaces** - Keep YAML schema consistent
4. **Update documentation** - Ensure README reflects any interface changes
5. **Test thoroughly** - All examples must work before release
6. **Follow template patterns** - Use existing job/stage templates when possible

### Development Workflow

1. **Create feature branch** from develop
2. **Make changes** to modules or pipeline templates
3. **Test locally** using example configurations
4. **Commit with appropriate prefix** (e.g., `[ado] feat: new feature`)
5. **Push and validate** pipeline execution
6. **Add `[release]` flag** when ready for publication
7. **Review and approve** the auto-created PR
8. **Merge to main** triggers automatic publication

## License

See [LICENSE](LICENSE) file for details.