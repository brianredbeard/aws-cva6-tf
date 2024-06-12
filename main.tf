provider "aws" {
  region = var.region
}

resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
}

resource "aws_subnet" "subnet" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.subnet_cidr
  availability_zone = "us-west-2c"  # Specify the availability zone for the subnet
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route" "route" {
  route_table_id         = aws_route_table.rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id
}

resource "aws_iam_role" "fpga_role" {
  name = "fpga-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_instance_profile" "fpga_profile" {
  name = "fpga-profile"
  role = aws_iam_role.fpga_role.name
}

resource "aws_security_group" "fpga_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = tls_private_key.ssh_key.public_key_openssh
}

resource "aws_instance" "fpga_instance" {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.subnet.id
  iam_instance_profile = aws_iam_instance_profile.fpga_profile.name
  vpc_security_group_ids = [aws_security_group.fpga_sg.id]  # Use security group IDs
  availability_zone = "us-west-2c"  # Specify the availability zone
  associate_public_ip_address = true  # Ensure the instance gets a public IP

  user_data = file("cloud-config.yaml")  # Add cloud-config.yaml as user data

  dynamic "instance_market_options" {
    for_each = var.use_spot_instance ? [1] : []
    content {
      market_type = "spot"
      spot_options {
      }
    }
  }

  provisioner "local-exec" {
    command = <<EOT
      echo "${tls_private_key.ssh_key.private_key_pem}" > private_key.pem
      chmod 400 private_key.pem
    EOT
  }
}

