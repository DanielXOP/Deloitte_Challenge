terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "6.0.0"
    }
  }
}

# AWS Provider Configuration
provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "Daniel-vpc" {
  cidr_block = "10.1.0.0/16"
  tags = {
    Name = "Daniel-VPC"
  }
}

resource "aws_subnet" "Daniel-subnet-mgmt" {
  vpc_id            = aws_vpc.Daniel-vpc.id
  cidr_block        = "10.1.0.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "Daniel-Subnet-mgmt"
  }
}

resource "aws_subnet" "Daniel-subnet-spoke1" {
  vpc_id            = aws_vpc.Daniel-vpc.id
  cidr_block        = "10.1.1.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "Daniel-Subnet-spoke1"
  }
}

resource "aws_subnet" "Daniel-subnet-spoke2" {
  vpc_id            = aws_vpc.Daniel-vpc.id
  cidr_block        = "10.1.2.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "Daniel-Subnet-spoke2"
  }
}

resource "aws_security_group" "daniel-sg-mgmt" {
  name        = "allow_ssh_and_http_for_mgmt"
  description = "Allow SSH and HTTP traffic"
  vpc_id      = aws_vpc.Daniel-vpc.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.1.0.0/16"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.1.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "daniel-sg-mgmt"
  }
}

resource "aws_security_group" "daniel-sg-spoke2" {
  name        = "allow_ssh_and_http_for_spoke2"
  description = "Allow SSH and HTTP traffic"
  vpc_id      = aws_vpc.Daniel-vpc.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = [aws_security_group.daniel-sg-mgmt.id]
    # Allow SSH from the management security group
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.daniel-sg-mgmt.id]
    # Allow SSH from the management security group
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "daniel-sg-spoke2"
  }
}

resource "aws_instance" "my-server-mgmt" {
  ami           = "ami-05ffe3c48a9991133"
  instance_type = "t2.micro"
  key_name = var.key_name
  subnet_id = aws_subnet.Daniel-subnet-mgmt.id
  vpc_security_group_ids = [aws_security_group.daniel-sg-mgmt.id]
  tags = {
    "Name" = "Daniel-Machine-Mgmt"
  }
}

resource "aws_instance" "my-server-spoke2" {
  ami           = "ami-05ffe3c48a9991133"
  instance_type = "t2.micro"
  key_name = var.key_name
  subnet_id = aws_subnet.Daniel-subnet-spoke2.id
  vpc_security_group_ids = [aws_security_group.daniel-sg-spoke2.id]
  tags = {
    "Name" = "Daniel-Machine-Spoke2"
  }
}

resource "aws_s3_bucket" "my-bucket-storage" {
  bucket = "daniel-bucket-storage"
  # By default, S3 buckets are created with default encryption Server side S3 managed keys.
  tags = {
    Name        = "Daniel-Bucket-Storage"
    Environment = "Dev"
  }
}

output "instance_private_ip-mgmt" {
  value = aws_instance.my-server-mgmt.private_ip
  description = "The public IP address of the server"
}

output "instance_private_ip-spoke2" {
  value = aws_instance.my-server-spoke2.private_ip
  description = "The public IP address of the server"
}
