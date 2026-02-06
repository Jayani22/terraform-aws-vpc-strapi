variable "aws_region" {
  description = "AWS region where resources will be created"
}

variable "env" {
  description = "Environment name like dev or test"
}

variable "az" {
  description = "Availability Zone"
}

variable "az_2" {
  description = "Availability Zone 2"
}

variable "public_key_path" {
    description = "Path to SSH public key"
}

variable "instance_type" {
    description = "Instance-Type"
}

variable "ami_id" {
    description = "AMI"
}