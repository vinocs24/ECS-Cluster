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
        Name = "demo-vpc-subnet1"
    }
}


#Public2
resource "aws_subnet" "demo-vpc-subnet2" {
    vpc_id     = aws_vpc.demo-vpc.id
    cidr_block = var.public2_subnet_cidr_block
    availability_zone = "us-west-2b"

    tags = {
        Name = "demo-vpc-subnet2"
    }
}


#Private
resource "aws_subnet" "demo-vpc-subnet3" {
    vpc_id     = aws_vpc.demo-vpc.id
    cidr_block = var.private_subnet_cidr_block
    availability_zone = "us-west-2c"

    tags = {
        Name = "demo-vpc-subnet3"
    }
}


# Route Tables public
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
 
  tags = {
        Name = "demo-SG"
    }
  
}


#NAT
resource "aws_eip" "demo-eip" {
vpc      = true
}
resource "aws_nat_gateway" "demo-nat-gw" {
allocation_id = aws_eip.demo-eip.id
subnet_id = aws_subnet.demo-vpc-subnet1.id
depends_on = [aws_internet_gateway.demo-vpc-internet-gateway]
}

# Terraform Training VPC for NAT
resource "aws_route_table" "demo-private" {
    vpc_id = aws_vpc.demo-vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.demo-nat-gw.id
    }

    tags = {
        Name = "demo-private-1"
    }
}

#Route Tables public
resource "aws_route_table_association" "demo-private-1-a" {
    subnet_id = aws_subnet.demo-vpc-subnet3.id
    route_table_id = aws_route_table.demo-private.id
}


#ECS
resource "aws_ecs_cluster" "main" {
    name = var.ecs_cluster_name
}

resource "aws_autoscaling_group" "ecs-cluster" {
    availability_zone = var.availability_zone
    name = var.ecs_cluster_name
    min_size = var.autoscale_min
    max_size = var.autoscale_max
    desired_capacity = var.autoscale_desired
    health_check_type = "EC2"
    launch_configuration = aws_launch_configuration.ecs.name
    vpc_zone_identifier = [aws_subnet.demo-vpc-subnet3.id]
}

resource "aws_launch_configuration" "ecs" {
    name = var.ecs_cluster_name
    image_id = lookup(var.amis, var.region)
    instance_type = var.instance_type
    security_groups = [aws_security_group.demo-vpc-security-group.id]
    iam_instance_profile = aws_iam_instance_profile.ecs.name
    # TODO: is there a good way to make the key configurable sanely?
    key_name = var.key_name
    associate_public_ip_address = true
    user_data = "#!/bin/bash\necho ECS_CLUSTER='${var.ecs_cluster_name}' > /etc/ecs/ecs.config"
}


resource "aws_iam_role" "ecs_host_role" {
    name = "ecs_host_role"
    assume_role_policy = file("ecs-role.json")
}

resource "aws_iam_role_policy" "ecs_instance_role_policy" {
    name = "ecs_instance_role_policy"
    policy = file("ecs-instance-role-policy.json")
    role = aws_iam_role.ecs_host_role.id
}

resource "aws_iam_role" "ecs_service_role" {
    name = "ecs_service_role"
    assume_role_policy = file("ecs-role.json")
}

resource "aws_iam_role_policy" "ecs_service_role_policy" {
    name = "ecs_service_role_policy"
    policy = file("ecs-service-role-policy.json")
    role = aws_iam_role.ecs_service_role.id
}

resource "aws_iam_instance_profile" "ecs" {
    name = "ecs-instance-profile"
    path = "/"
    roles = [aws_iam_role.ecs_host_role.name]
}
