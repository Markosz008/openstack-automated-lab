terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
}

# 1. AWS Biztonsági Csoport (Tűzfal az Ubuntu gépnek)
resource "aws_security_group" "openstack_host_sg" {
  name        = "openstack-host-sg"
  description = "Allow SSH and OpenStack Horizon dashboard"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Élesben ide a saját IP-d jönne
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 2. Az Ubuntu 22.04 LTS gép elindítása (t3.large, 30GB gp3)
resource "aws_instance" "openstack_host" {
  ami           = "ami-0c905937c14bd22b0" # A legutóbb sikeresen letesztelt AMI ID-d
  instance_type = "t3.large"
  security_groups = [aws_security_group.openstack_host_sg.name]
  
  // Feltételezzük, hogy a Jenkins szerveren a ~/.ssh/id_rsa.pub kulcsot használod
  key_name = "openstack-lab-key" 

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  tags = {
    Name = "OpenStack-Lab-Host"
  }
}

# KIMENET: Ezt olvassa ki a Jenkins az Ansible számára
output "ec2_public_ip" {
  value       = aws_instance.openstack_host.public_ip
  description = "Az AWS gép nyilvános IP címe"
}