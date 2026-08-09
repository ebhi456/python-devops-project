data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

resource "aws_instance" "employee_api_ec2_instance" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.ec2_instance_type

  subnet_id = aws_subnet.public.id
  key_name = var.key_name

  associate_public_ip_address = true

  vpc_security_group_ids = [
    aws_security_group.employee_api_sg.id
  ]

  iam_instance_profile = aws_iam_instance_profile.employee_api_ec2_instance_profile.name

  user_data = <<-EOF
    #!/bin/bash
    set -e

    apt-get update -y
    apt-get install -y docker.io awscli

    systemctl start docker
    systemctl enable docker

    usermod -aG docker ubuntu

    mkdir -p /home/ubuntu/employee_api
    cd /home/ubuntu/employee_api

    echo "employee api server initialisation is complete"
  EOF

  root_block_device {
    volume_size = var.ec2_root_volume_size
    volume_type = var.ec2_root_volume_type
  }

  tags = {
    Name        = "${var.project_name}-ec2-instance"
    Project     = var.project_name
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}