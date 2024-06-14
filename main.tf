provider "aws" {
  region = var.region
}

resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = "4096"
}

resource "local_sensitive_file" "pem_priv_file" {
  content         = tls_private_key.ssh_key.private_key_openssh
  filename        = "${path.module}/private_key.pem"
  file_permission = "0600"
}

resource "local_file" "pem_pub_file" {
  content         = tls_private_key.ssh_key.public_key_openssh
  filename        = "${path.module}/public_key.pem"
  file_permission = "0444"
}

resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = trimspace(tls_private_key.ssh_key.public_key_openssh)
}

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic"

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

resource "aws_instance" "cva6" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.deployer.key_name
  security_groups             = [aws_security_group.allow_ssh.name]
  user_data                   = file("${path.module}/cloud-config.yaml")
  associate_public_ip_address = true

  root_block_device {
    volume_size = 40
    volume_type = "gp3"
  }

  metadata_options {
    http_tokens                 = "required"
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 2
  }

  dynamic "instance_market_options" {
    for_each = var.use_spot_instance ? [1] : []
    content {
      market_type = "spot"
      spot_options {
        max_price          = var.spot_price != null ? var.spot_price : null
        spot_instance_type = "one-time"
      }
    }
  }


  tags = {
    Name = "CVA6-Instance"
  }
}

resource "aws_eip" "cva6" {
  instance = aws_instance.cva6.id
}


output "instance_public_ip" {
  description = "The public IP address of the EC2 instance"
  value       = aws_eip.cva6.public_ip
}

output "private_key" {
  value     = trimspace(tls_private_key.ssh_key.private_key_openssh)
  sensitive = true
}
