aws_region = "us-east-1"
environment = "dev"
vpc_cidr = "10.0.0.0/16"

public_subnet_cidrs = [
  "10.0.1.0/24",
  "10.0.2.0/24"
]

private_subnet_cidrs = [
  "10.0.101.0/24",
  "10.0.102.0/24"
]

allowed_ssh_cidr = "106.200.31.185/32"
instance_type = "t3.micro"
key_pair_name = "strapi-key-dev"
ecr_repo_name = "strapi-app"
