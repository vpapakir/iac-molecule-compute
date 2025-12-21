terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "main" {
  most_recent = true
  owners      = [var.ami_owner]

  filter {
    name   = "name"
    values = [var.ami_name_filter]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-vpc"
  })
}

resource "aws_subnet" "main" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = var.create_public_ip

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-subnet"
  })
}

resource "aws_internet_gateway" "main" {
  count  = var.create_public_ip ? 1 : 0
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-igw"
  })
}

resource "aws_route_table" "main" {
  count  = var.create_public_ip ? 1 : 0
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main[0].id
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-rt"
  })
}

resource "aws_route_table_association" "main" {
  count          = var.create_public_ip ? 1 : 0
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.main[0].id
}

resource "aws_security_group" "main" {
  name_prefix = "${var.name_prefix}-sg"
  vpc_id      = aws_vpc.main.id

  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-sg"
  })
}

resource "aws_key_pair" "main" {
  count      = var.ssh_public_key != null ? 1 : 0
  key_name   = "${var.name_prefix}-key"
  public_key = var.ssh_public_key

  tags = var.tags
}

resource "aws_instance" "main" {
  ami                    = var.ami_id != null ? var.ami_id : data.aws_ami.main.id
  instance_type          = var.instance_type
  key_name               = var.ssh_public_key != null ? aws_key_pair.main[0].key_name : null
  vpc_security_group_ids = [aws_security_group.main.id]
  subnet_id              = aws_subnet.main.id
  user_data              = var.user_data

  root_block_device {
    volume_type = var.root_volume_type
    volume_size = var.root_volume_size
    encrypted   = var.encrypt_root_volume
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-instance"
  })
}