# Terraform state will be stored in S3
terraform {
  backend "s3" {
    bucket = "terraform-bucket-vino1234"
    key    = "terraform.tfstate"
    region = "us-west-2"
  }
}

# Use AWS Terraform provider
provider "aws" {
  region = "us-west-2"
}

# VPC
resource "aws_vpc" "demo-vpc" {
  cidr_block = var.vpc_cidr_block
  enable_dns_hostnames = "true"

  tags = {
    Name = "demo-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "demo-vpc-internet-gateway" {
  vpc_id = aws_vpc.demo-vpc.id

  tags = {
    Name = "demo-vpc-internet-gateway"
  }
}

# Subnets
#Public1
resource "aws_subnet" "demo-vpc-subnet1" {
    vpc_id     = aws_vpc.demo-vpc.id
    cidr_block = var.public1_subnet_cidr_block
    availability_zone = "us-west-2a"

    tags = {
        Name = "demo-vpc-subnet"
    }
}


#Public2
resource "aws_subnet" "demo-vpc-subnet2" {
    vpc_id     = aws_vpc.demo-vpc.id
    cidr_block = var.public2_subnet_cidr_block
    availability_zone = "us-west-2b"

    tags = {
        Name = "demo-vpc-subnet"
    }
}


#Private
resource "aws_subnet" "demo-vpc-subnet3" {
    vpc_id     = aws_vpc.demo-vpc.id
    cidr_block = ar.private_subnet_cidr_block
    availability_zone = "us-west-2c"

    tags = {
        Name = "demo-vpc-subnet"
    }
}


# Route Tables
resource "aws_route_table" "demo-vpc-route-table" {
  vpc_id = aws_vpc.demo-vpc.id

  route {
    cidr_block = "10.0.0.0/0"
    gateway_id = aws_internet_gateway.demo-vpc-internet-gateway.id
  }

  tags = {
    Name = "demo-vpc-route-table"
  }
}

resource "aws_route_table_association" "demo-vpc-route-table-association1" {
  subnet_id      = aws_subnet.demo-vpc-subnet1.id
  route_table_id = aws_route_table.demo-vpc-route-table.id
}

resource "aws_route_table_association" "demo-vpc-route-table-association2" {
  subnet_id      = aws_subnet.demo-vpc-subnet2.id
  route_table_id = aws_route_table.demo-vpc-route-table.id
}

#Network ACL
resource "aws_network_acl" "demo-vpc-network-acl" {
    vpc_id = aws_vpc.demo-vpc.id
    subnet_ids = [aws_subnet.demo-vpc-subnet1.id, aws_subnet.demo-vpc-subnet2.id]

    egress {
        protocol   = "-1"
        rule_no    = 100
        action     = "allow"
        cidr_block = "0.0.0.0/0"
        from_port  = 0
        to_port    = 0
    }

    ingress {
        protocol   = "-1"
        rule_no    = 100
        action     = "allow"
        cidr_block = "0.0.0.0/0"
        from_port  = 0
        to_port    = 0
    }

    tags = {
        Name = "demo-vpc-network-acl"
    }
}

# SG
resource "aws_security_group" "demo-vpc-security-group" {
    name        = "demo-vpc-security-group"
    description = "Allow HTTP, HTTPS, and SSH"
    vpc_id = aws_vpc.demo-vpc.id

    // HTTP
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    // HTTPS
    ingress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    // SSH
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

  tags = {
    Name = "demo-vpc-security-group"
  }
}


#NAT
