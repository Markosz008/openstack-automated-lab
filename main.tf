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

# 1. GENERÁLT KULCSPÁR IMPORTÁLÁSA (Ez garantálja az egyezést!)
resource "aws_key_pair" "jenkins_mac_key" {
  key_name   = "openstack-lab-key-dynamic"
  public_key = file("/Users/markosz/.ssh/id_rsa.pub") # Beolvassa a Mac-ed publikus kulcsát
}

# 2. AWS Biztonsági Csoport
resource "aws_security_group" "openstack_host_sg" {
  name        = "openstack-host-sg"
  description = "Allow SSH and OpenStack Horizon dashboard"

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

# 3. Az Ubuntu gép indítása az ÚJ kulccsal
resource "aws_instance" "openstack_host" {
  ami           = "ami-0c905937c14bd22b0"
  instance_type = "t3.large"
  security_groups = [aws_security_group.openstack_host_sg.name]
  
  # Itt már a dinamikusan importált kulcsra hivatkozunk:
  key_name = aws_key_pair.jenkins_mac_key.key_name 

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  tags = {
    Name = "OpenStack-Lab-Host"
  }
}

output "ec2_public_ip" {
  value       = aws_instance.openstack_host.public_ip
  description = "Az AWS gép nyilvános IP címe"
}