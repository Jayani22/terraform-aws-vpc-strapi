#!/bin/bash
set -e

# Update system
dnf update -y

# Install Docker (CORRECT for Amazon Linux)
dnf install -y docker awscli

# Start Docker
systemctl start docker
systemctl enable docker

# Allow ec2-user to use docker (good practice)
usermod -aG docker ec2-user

# Login to Amazon ECR
aws ecr get-login-password --region us-east-1 | \
docker login --username AWS --password-stdin \
385046010663.dkr.ecr.us-east-1.amazonaws.com

# Pull Strapi image
docker pull 385046010663.dkr.ecr.us-east-1.amazonaws.com/strapi-app:latest

# Run Strapi container (IMPORTANT FIX HERE)
docker run -d \
  -p 1337:1337 \
  -e HOST=0.0.0.0 \
  -e PORT=1337 \
  --name strapi \
  385046010663.dkr.ecr.us-east-1.amazonaws.com/strapi-app:latest