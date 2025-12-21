data "civo_size" "main" {
  filter {
    key    = "name"
    values = [var.instance_size]
  }
}

data "civo_disk_image" "main" {
  filter {
    key    = "name"
    values = [var.disk_image]
  }
}

resource "civo_network" "main" {
  label  = "${var.name_prefix}-network"
  region = var.region
}

resource "civo_firewall" "main" {
  name           = "${var.name_prefix}-firewall"
  network_id     = civo_network.main.id
  region         = var.region
  create_default_rules = false

  dynamic "ingress_rule" {
    for_each = var.firewall_rules
    content {
      protocol   = ingress_rule.value.protocol
      port_range = ingress_rule.value.port_range
      cidr       = ingress_rule.value.cidr
      label      = ingress_rule.value.label
    }
  }

  egress_rule {
    protocol   = "tcp"
    port_range = "1-65535"
    cidr       = ["0.0.0.0/0"]
    label      = "All TCP outbound"
  }

  egress_rule {
    protocol   = "udp"
    port_range = "1-65535"
    cidr       = ["0.0.0.0/0"]
    label      = "All UDP outbound"
  }

  egress_rule {
    protocol   = "icmp"
    cidr       = ["0.0.0.0/0"]
    label      = "All ICMP outbound"
  }
}

resource "civo_ssh_key" "main" {
  count      = var.ssh_public_key != null ? 1 : 0
  name       = "${var.name_prefix}-key"
  public_key = var.ssh_public_key
}

resource "civo_instance" "main" {
  hostname     = "${var.name_prefix}-instance"
  size         = data.civo_size.main.name
  disk_image   = data.civo_disk_image.main.id
  region       = var.region
  network_id   = civo_network.main.id
  firewall_id  = civo_firewall.main.id
  sshkey_id    = var.ssh_public_key != null ? civo_ssh_key.main[0].id : null
  script       = var.user_data
  tags         = var.tags

  public_ip_required = var.create_public_ip ? "create" : "none"
}