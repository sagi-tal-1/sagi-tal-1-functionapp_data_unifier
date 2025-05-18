data "aws_availability_zones" "available" {}
data "aws_caller_identity" "current" {}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

locals {
  name   = "ex-${basename(path.cwd)}"
  region = "us-east-1"

  
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)

  user_data = <<-EOT
    #!/bin/bash
    echo "Hello Terraform!"
  EOT

  tags = {
    Name       = local.name
    Example    = local.name
    Repository = "https://github.com/terraform-aws-modules/terraform-aws-ec2-instance"
  }
}

resource "aws_key_pair" "my_key" {
  key_name   = "my-ec2-key"
  public_key = file("~/.ssh/my-ec2-key.pub")
}


################################################################################
# iam
################################################################################
resource "aws_iam_role" "test_role" {
  name = "test_role"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    tag-key = "tag-value"
  }
}

resource "aws_iam_role_policy_attachment" "test_attachment" {
  role       = aws_iam_role.test_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_instance_profile" "test_profile" {
  name = "example_profile"
  role = aws_iam_role.test_role.name
}

################################################################################
# VPC Module
################################################################################

module "vpc" {
  for_each = var.vpc
  source = "terraform-aws-modules/vpc/aws"
  version  = "5.19.0"

  name = local.name
  cidr            = lookup(each.value, "cidr", "10.0.0.0/16")

  azs             = lookup(each.value, "azs", local.azs)
  private_subnets = [for k, v in local.azs : cidrsubnet(each.value.cidr, 8, k)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(each.value.cidr, 8, k + 4)]
  # database_subnets    = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 8)]
  # elasticache_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 12)]
  # redshift_subnets    = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 16)]
  # intra_subnets       = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 20)]

private_subnet_tags = {
    Tier = "private"
    Name = "${local.name}-private"
  }

  public_subnet_tags = {
    Tier = "public"
    Name = "${local.name}-public"
  }


  # public_subnet_names omitted to show default name generation for all three subnets
  # database_subnet_names    = ["DB Subnet One"]
  # elasticache_subnet_names = ["Elasticache Subnet One", "Elasticache Subnet Two"]
  # redshift_subnet_names    = ["Redshift Subnet One", "Redshift Subnet Two", "Redshift Subnet Three"]
  # intra_subnet_names       = []

  # create_database_subnet_group  = false
  # manage_default_network_acl    = false
  # manage_default_route_table    = false
  # manage_default_security_group = false

  enable_dns_hostnames = true
  enable_dns_support   = true

  enable_nat_gateway = true
  single_nat_gateway = true

  # customer_gateways = {
  #   IP1 = {
  #     bgp_asn     = 65112
  #     ip_address  = "1.2.3.4"
  #     device_name = "some_name"
  #   },
  #   IP2 = {
  #     bgp_asn    = 65112
  #     ip_address = "5.6.7.8"
  #   }
  # }

  # enable_vpn_gateway = true

  # enable_dhcp_options              = true
  # dhcp_options_domain_name         = "service.consul"
  # dhcp_options_domain_name_servers = ["127.0.0.1", "10.10.0.2"]

  # VPC Flow Logs (Cloudwatch log group and IAM role will be created)
  # vpc_flow_log_iam_role_name            = "vpc-complete-example-role"
  # vpc_flow_log_iam_role_use_name_prefix = false
  # enable_flow_log                       = true
  # create_flow_log_cloudwatch_log_group  = true
  # create_flow_log_cloudwatch_iam_role   = true
  # flow_log_max_aggregation_interval     = 60

  tags = local.tags
}

output "private_subnets" {
  value = {
    for k, v in module.vpc : k => v.private_subnets
  }
  description = "List of private subnets for each VPC"
}

resource "aws_security_group" "example" {
  name   = "sg"
  vpc_id = module.vpc["map"].vpc_id


  ingress = []
  egress  = []
}


################################################################################
# ec2 Module
################################################################################
module "ec2_instance" {
  for_each = var.ec2_instance
  
  source  = "terraform-aws-modules/ec2-instance/aws"
  version  = "4.3.0"

  name                   = each.key
  ami                    = data.aws_ami.ubuntu.id

  iam_instance_profile   = aws_iam_instance_profile.test_profile.name

  instance_type          = each.value.instance_type
  key_name               = aws_key_pair.my_key.key_name 
  monitoring             = true
  vpc_security_group_ids = [aws_security_group.example.id]
  subnet_id              = module.vpc["map"].private_subnets[0]


  private_ip             = null
  ipv6_address_count     = 0
  ipv6_addresses         = []

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}



