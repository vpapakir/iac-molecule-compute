data "oci_identity_availability_domains" "main" {
  compartment_id = var.compartment_id
}

data "oci_core_images" "main" {
  compartment_id           = var.compartment_id
  operating_system         = var.image_operating_system
  operating_system_version = var.image_operating_system_version
  shape                    = var.instance_shape

  filter {
    name   = "display_name"
    values = [var.image_name_filter]
    regex  = true
  }
}

resource "oci_core_vcn" "main" {
  compartment_id = var.compartment_id
  cidr_blocks    = [var.vcn_cidr]
  display_name   = "${var.name_prefix}-vcn"
  dns_label      = replace(var.name_prefix, "-", "")

  freeform_tags = var.tags
}

resource "oci_core_internet_gateway" "main" {
  count          = var.create_public_ip ? 1 : 0
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.main.id
  display_name   = "${var.name_prefix}-igw"
  enabled        = true

  freeform_tags = var.tags
}

resource "oci_core_route_table" "main" {
  count          = var.create_public_ip ? 1 : 0
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.main.id
  display_name   = "${var.name_prefix}-rt"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.main[0].id
  }

  freeform_tags = var.tags
}

resource "oci_core_subnet" "main" {
  compartment_id             = var.compartment_id
  vcn_id                     = oci_core_vcn.main.id
  cidr_block                 = var.subnet_cidr
  display_name               = "${var.name_prefix}-subnet"
  dns_label                  = "subnet"
  route_table_id             = var.create_public_ip ? oci_core_route_table.main[0].id : oci_core_vcn.main.default_route_table_id
  security_list_ids          = [oci_core_security_list.main.id]
  prohibit_public_ip_on_vnic = !var.create_public_ip

  freeform_tags = var.tags
}

resource "oci_core_security_list" "main" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.main.id
  display_name   = "${var.name_prefix}-sl"

  dynamic "ingress_security_rules" {
    for_each = var.ingress_rules
    content {
      protocol = ingress_security_rules.value.protocol
      source   = ingress_security_rules.value.source

      tcp_options {
        min = ingress_security_rules.value.port_min
        max = ingress_security_rules.value.port_max
      }
    }
  }

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
  }

  freeform_tags = var.tags
}

resource "oci_core_instance" "main" {
  compartment_id      = var.compartment_id
  availability_domain = data.oci_identity_availability_domains.main.availability_domains[0].name
  display_name        = "${var.name_prefix}-instance"
  shape               = var.instance_shape

  dynamic "shape_config" {
    for_each = var.instance_shape_config != null ? [var.instance_shape_config] : []
    content {
      ocpus         = shape_config.value.ocpus
      memory_in_gbs = shape_config.value.memory_in_gbs
    }
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.main.id
    display_name     = "${var.name_prefix}-vnic"
    assign_public_ip = var.create_public_ip
    hostname_label   = replace(var.name_prefix, "-", "")

    freeform_tags = var.tags
  }

  source_details {
    source_type = "image"
    source_id = var.image_id != null ? var.image_id : (
      length(data.oci_core_images.main.images) > 0 ?
      data.oci_core_images.main.images[0].id :
      "ocid1.image.oc1.iad.aaaaaaaag2uyozo7266bmg26j5ys4yandefokktime5rhriu5yapc2pxg6vq"
    )
    boot_volume_size_in_gbs = 50
  }

  launch_options {
    boot_volume_type                    = "PARAVIRTUALIZED"
    firmware                            = "UEFI_64"
    network_type                        = "PARAVIRTUALIZED"
    remote_data_volume_type             = "PARAVIRTUALIZED"
    is_pv_encryption_in_transit_enabled = true
  }

  instance_options {
    are_legacy_imds_endpoints_disabled = true
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    user_data           = var.user_data != null ? base64encode(var.user_data) : null
  }

  freeform_tags = var.tags
}