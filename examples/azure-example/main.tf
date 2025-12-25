terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
  skip_provider_registration = true
}

module "compute" {
  source = "../../iac/terraform/azure"
  
  name_prefix         = "vm"
  resource_group_name = "rg-weu-dev-gen-001"  # Replace with your resource group
  location           = "West Europe"
  vm_size            = "Standard_B2s"
  os_type            = "linux"
  admin_username     = "azureuser"
  ssh_public_key     = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAEAQDCjJqTtvhtKSZCgk+q4rdaxPq3huseDWXPl6MTCFpoYj69j5K92FBYYpKD4Abpn3clT2vi0+pBuL6JLjtqvjnHOWOQPLr4P+WjryOwLI7MsHbVNIugLBey9Ook5xAWkpkklSdC5BLXHW6PosKYJUcauhiaum3s4TEZp45uoAkV72F4rXMPHsDrDAJ/Q94tTzXbDW89N646POM0kf89zdOTETXNE2kMBdHNCJjMuKpPjV1HGihB8z4lRf+DXU7OBZEC8ps+79k1FnwyX3KDKDOfqExbednqYIyDgqtJqwKJ/sfC603+6GS79GJcJRPfhJYlhpR7ooAIi1PJFRZhdOsXjyHv8RXowMFF8MK9dEc1CQwOm7N5eE5FuzQ8yM8KPddo+o+T1tt23ulm/Wj2exOSMZxKQZ+sXJXS2XvZgxib1QhRaC/ljGRpndgwbNV85V2ureKoGuYiqQ5ShsSHPQhyBCmrOQaimT6uJsxwLTnooS533WTriKStJHij7Wv98rRUFRsv2Oalme0bmEddg7RXzBnSvGi84xLfub2rhp4gQU8kmYcnL4TogV83Aic2Vg0W13TSZV40cf0xQN4hiEvyDR3565a5PK7D9qJdYzZie0oE+PkxgVkk03iEW0bPLVfMo+EM6FXh4x/ySTn0+FDwXLsTaVzLHn36EKGifHhFMtEav7FO3tmtNtgSxdfZ20h/wBId+PY7YIjvB4e4QVga9hg9xKWv6iVevhfNNM6/xLZUeWFFQW2YPM4kkH0ANbxsv/PpSS71qtuR1mETijFdI1k/jxXgcls1vjI0eRkZHHkFDu+VILqDyHIxq4TGpGtPq73YXgW8VsLrHWxYs9IjtI93N+oOVz9FTuTaf7mjN+p3V2G7ox2QwHBXuHeGR+5Ir6/KsowuBurkZcrdYAhZkpY64+33zIF59dBmQ36JQ3T3qLPXGnqpJFdChutBaF4NdOqV2L90UnNreWozAVIK6o/IHvlQBqcpZQEwOjUz1VG2lt5Y3aQK0luJXBmFh/lZbV4coNZvlxH7ySoy4j397G9xJ0gG9CJCLjlGwdlCpM7nqHSbAOc3D2PCZeAa5UcT68w42nc8JPaZqMcmz6DhvTO+PiFc2qClPZXrkL3JO1P9LMMS5RKFQ3m6+EwRWyvvout4CRVyn13KntRVDSGSaTFL8Wem2utkRWmWLZf/e0r1SeoEk2dyXC1XzgbsqBtcbie72M2c/mw9qj9oMG4EZCgiB8I65MR/p0rnwuGl1olR02wgcflK4z/YeO+HnNU/KK07IOAvrfNirc+vNrPPEcaB45kYMzyUT0ZufFDtXjMDTWhJD83D9VLX1H8BC3rGgjGQRBlHaMJp01zzyjnH"  # Replace with your SSH key
  create_public_ip   = true
  os_disk_type       = "Standard_LRS"
  
  tags = {
    Environment = "dev"
    Project     = "compute-molecule-test"
    Owner       = "pipeline"
  }
}

output "vm_id" {
  value = module.compute.vm_id
}

output "public_ip" {
  value = module.compute.public_ip_address
}

output "ssh_command" {
  value = module.compute.ssh_connection_command
}