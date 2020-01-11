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

variable "public_subnet_cidr_block" {
  description = "Public Subnet"
  default     = "10.10.1.0/24"
}

variable "private_subnet_cidr_block" {
  description = "Private Subnet"
  default     = "10.10.2.0/24"
}

variable "availability_zones" {
  description = "Availability Zones"
  default     = "us-west-2a,us-west-2b,us-west-2c"
}
