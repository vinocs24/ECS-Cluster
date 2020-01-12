variable "region" {
  description = "AWS Region"
  default     = "us-west-2"
}

variable "key_name" {
  description = "SSH key name to access the EC2 instances"
  default     = "rds-key"
}

variable "vpc_cidr_block" {
  description = "VPC network"
  default     = "10.10.0.0/16"
}

variable "public1_subnet_cidr_block" {
  description = "Public Subnet"
  default     = "10.10.1.0/24"
}

variable "public2_subnet_cidr_block" {
  description = "Public Subnet"
  default     = "10.10.2.0/24"
}

variable "private_subnet_cidr_block" {
  description = "Private Subnet"
  default     = "10.10.3.0/24"
}

variable "availability_zones" {
  description = "Availability Zones"
  default     = "us-west-2a,us-west-2b,us-west-2c"
}

variable "ecs_cluster_name" {
    description = "The name of the Amazon ECS cluster."
    default = "main"
}

variable "autoscale_min" {
    default = "1"
    description = "Minimum autoscale (number of EC2)"
}

variable "autoscale_max" {
    default = "10"
    description = "Maximum autoscale (number of EC2)"
}

variable "autoscale_desired" {
    default = "4"
    description = "Desired autoscale (number of EC2)"
}

variable "amis" {
    description = "Which AMI to spawn. Defaults to the AWS ECS optimized images."
    default = {
        us-west-2 = "ami-ddc7b6b7"
    }
}

variable "instance_type" {
    default = "t2.micro"
}
