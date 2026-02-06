variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, test, prod)"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
}

variable "allowed_ssh_cidr" {
  description = "CIDR allowed for SSH access"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "key_pair_name" {
  description = "Key pair name"
  type        = string
}

variable "ecr_repo_name" {
  description = "ECR repository name"
  type        = string
}

variable "app_keys" {
  description = "Strapi app keys"
  type        = string
  sensitive   = true
}

variable "admin_jwt_secret" {
  description = "Strapi admin JWT secret"
  type        = string
  sensitive   = true
}

variable "jwt_secret" {
  description = "Strapi JWT secret"
  type        = string
  sensitive   = true
}

variable "api_token_salt" {
  description = "Strapi API token salt"
  type        = string
  sensitive   = true
}
