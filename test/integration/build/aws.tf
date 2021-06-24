# AWS Terraform Templates for InSpec Testing

terraform {
  required_version = ">= 0.12"
}

# Configure variables
variable "aws_enable_creation" {}
variable "aws_enable_cli_calls" {}
variable "aws_enable_privileged_resources" {}
variable "aws_create_configuration_recorder" {}

variable "aws_region" {}
variable "aws_availability_zone" {}

variable "aws_vpc_cidr_block" {}
variable "aws_vpc_instance_tenancy" {}
variable "aws_vpc_name" {}
variable "aws_vpc_dhcp_options_name" {}
variable "aws_vpc_endpoint_name" {}
variable "aws_subnet_name" {}

provider "aws" {
  version = ">= 2.0.0"
  region  = var.aws_region
}

data "aws_caller_identity" "creds" {}

data "aws_region" "current" {}

# default VPC always exists for every AWS region
data "aws_vpc" "default" {
  default = "true"
}

resource "aws_vpc" "inspec_vpc" {
  count            = var.aws_enable_creation
  cidr_block       = var.aws_vpc_cidr_block
  instance_tenancy = var.aws_vpc_instance_tenancy

  tags = {
    Name = var.aws_vpc_name
  }
}

resource "aws_vpc_dhcp_options" "inspec_dopt" {
  count               = var.aws_enable_creation
  domain_name_servers = ["AmazonProvidedDNS"]
  ntp_servers         = ["127.0.0.1"]

  tags = {
    Name = var.aws_vpc_dhcp_options_name
  }
}

resource "aws_vpc_dhcp_options_association" "inspec_vpc_dopt_assoc" {
  count           = var.aws_enable_creation
  vpc_id          = aws_vpc.inspec_vpc[0].id
  dhcp_options_id = aws_vpc_dhcp_options.inspec_dopt[0].id
}

resource "aws_subnet" "inspec_subnet" {
  count             = var.aws_enable_creation
  vpc_id            = aws_vpc.inspec_vpc[0].id
  availability_zone = var.aws_availability_zone
  cidr_block        = cidrsubnet(aws_vpc.inspec_vpc[0].cidr_block, 1, 1)

  # will result in /28 (or 16) IP addresses

  tags = {
    Name = var.aws_subnet_name
  }
}
