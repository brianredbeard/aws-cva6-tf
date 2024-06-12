provider "aws" {
  region = var.region
}

resource "aws_key_pair" "generated_key" {
  key_name   = "generated-key"
  public_key = file("${path.module}/generated-key.pub")
}

resource "tls_private_key" "generated_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "local_file" "private_key" {
  content  = tls_private_key.generated_key.private_key_pem
  filename = "${path.module}/generated-key.pem"
}

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic"
  vpc_id      = "default"

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
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.generated_key.key_name
  security_groups        = [aws_security_group.allow_ssh.name]
  user_data              = file("${path.module}/cloud-config.yaml")
  associate_public_ip_address = true

  metadata_options {
    http_tokens = "required"
    http_endpoint = "enabled"
    http_put_response_hop_limit = 2
  }

  dynamic "instance_market_options" {
    for_each = var.use_spot_instance ? [1] : []
    content {
      market_type = "spot"
      spot_options {
        max_price = var.spot_price
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

