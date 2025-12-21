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
2. Push changes to repository
3. Automated pipelines execute:
   - Terraform plan
   - Code linting
   - Static code analysis
   - Resource provisioning/updates

### Multi-Platform CI/CD
- **GitHub Actions** (`.github/workflows/` directory)
- **Azure DevOps Pipelines** (`.azure/` directory)
- **AWS CodePipeline** (`.aws/` directory)

All three platforms execute identical plan-test-release workflows:
1. **Plan**: Terraform init and plan for all modules
2. **Test**: Code formatting, validation, and security scanning
3. **Release**: Module publishing to Terraform Registry (main branch only)

## Current Implementation

### Supported Cloud Providers

#### Azure (`iac/terraform/azure/`)
- **Resource**: Azure Virtual Machine (Linux/Windows)
- **Networking**: VNet, Subnet, NSG, Public IP (optional)
- **Features**: SSH key authentication, configurable VM sizes, custom images
- **Outputs**: VM details, networking info, SSH connection commands

#### AWS (`iac/terraform/aws/`)
- **Resource**: EC2 Instance
- **Networking**: VPC, Subnet, Security Group, Internet Gateway (optional)
- **Features**: Key pair management, configurable instance types, custom AMIs
- **Outputs**: Instance details, networking info, SSH connection commands

### Module Structure
Each cloud provider module includes:
- `main.tf` - Core resource definitions
- `variables.tf` - Input parameters
- `outputs.tf` - Exposed values for consumption
- `versions.tf` - Terraform/provider version constraints
- `terraform.tfvars.example` - Configuration examples

## Usage

### Module Publication
Modules are published to Terraform Cloud and referenced by URI:

```hcl
module "compute" {
  source  = "app.terraform.io/your-org/compute/azure"
  version = "~> 1.0"
  
  name_prefix         = "myapp-dev"
  resource_group_name = "rg-myapp-dev"
  location           = "East US"
  vm_size            = "Standard_B2s"
  os_type            = "linux"
  ssh_public_key     = var.ssh_public_key
}
```

### YAML-Driven Configuration (Planned)
Future implementation will support YAML parameter files:

```yaml
compute:
  provider: azure
  size: medium
  os: ubuntu-22.04
  region: eastus
  networking:
    public_ip: true
    allow_ssh: true
```

## Future Evolution

### Atomic Decomposition
Over time, individual components will be extracted into separate atoms:
- **VNet Atom**: Virtual network provisioning
- **Subnet Atom**: Subnet management
- **Disk Atom**: Storage provisioning
- **Alert Rules Atom**: Monitoring configuration

The compute molecule will then compose these atoms rather than managing resources directly.

### Additional Cloud Providers
- **Civo** (`iac/terraform/civo/`)
- **Oracle Cloud Infrastructure** (`iac/terraform/oci/`)

### Infrastructure as Code Tools
- **Ansible** (`iac/ansible/`) - Configuration management
- **Bicep** (`iac/bicep/`) - Azure-native templates
- **Scripts** (`iac/scripts/`) - Bash and PowerShell utilities

## Pipeline Configuration

### Commit Message-Based Pipeline Triggering
To avoid running all three pipelines simultaneously, use commit message prefixes to control which pipeline executes:

- `[ado]` - Triggers Azure DevOps pipeline
- `[gh]` - Triggers GitHub Actions pipeline  
- `[aws]` - Triggers AWS CodePipeline
- No prefix - Defaults to Azure DevOps pipeline

**Examples:**
```bash
git commit -m "fix: update terraform module"           # Runs Azure DevOps (default)
git commit -m "[gh] feat: add new feature"             # Runs GitHub Actions only
git commit -m "[aws] chore: update pipeline"           # Runs AWS CodePipeline only
git commit -m "[ado] docs: update README"              # Runs Azure DevOps only
```

### GitHub Actions
Workflow: `.github/workflows/plan-test-release.yml`
- Triggers on push to main/develop branches and PRs
- Uses hashicorp/setup-terraform action
- Runs Checkov for security scanning

### Azure DevOps
Pipeline: `.azure/provision.yaml`
- Multi-stage pipeline with dependencies
- Uses TerraformInstaller task
- Conditional release stage for main branch

### AWS CodePipeline
Infrastructure: `.aws/pipeline.yaml` (CloudFormation)
- Complete pipeline infrastructure as code
- CodeBuild projects for each stage
- S3 artifacts storage and IAM roles
- Deploy with: `cd .aws && ./deploy-pipeline.sh <github-owner> <github-token>`

## Repository Structure

```
iac-molecule-compute/
├── .aws/                      # AWS CodePipeline infrastructure
│   ├── pipeline.yaml          # CloudFormation template
│   └── deploy-pipeline.sh     # Deployment script
├── .azure/                    # Azure DevOps pipeline definitions
│   └── provision.yaml
├── .github/                   # GitHub Actions workflows
│   └── workflows/
│       └── plan-test-release.yml
├── iac/
│   ├── ansible/              # Ansible playbooks (future)
│   ├── bicep/                # Azure Bicep templates (future)
│   ├── scripts/              # Utility scripts
│   │   ├── bash/
│   │   └── powershell/
│   └── terraform/            # Terraform modules
│       ├── aws/              # AWS EC2 module
│       ├── azure/            # Azure VM module
│       ├── civo/             # Civo instance module (future)
│       └── oci/              # OCI compute module (future)
├── .gitignore
├── LICENSE
└── README.md
```

## Contributing

This molecule is designed for reusability across teams and projects. When contributing:

1. Maintain cloud-agnostic interfaces
2. Follow consistent naming conventions
3. Provide comprehensive examples
4. Update documentation for any interface changes
5. Ensure modules work with both GitHub Actions and Azure DevOps pipelines

## License

See [LICENSE](LICENSE) file for details.