resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "strapi-vpc-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = "${var.aws_region}${count.index == 0 ? "a" : "b"}"
  map_public_ip_on_launch = true

  tags = {
    Name        = "public-subnet-${count.index + 1}-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = "${var.aws_region}${count.index == 0 ? "a" : "b"}"

  tags = {
    Name        = "private-subnet-${count.index + 1}-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name        = "strapi-igw-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name        = "strapi-nat-eip-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name        = "strapi-nat-${var.environment}"
    Environment = var.environment
  }

  depends_on = [aws_internet_gateway.this]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name        = "public-rt-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this.id
  }

  tags = {
    Name        = "private-rt-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

resource "aws_security_group" "alb" {
  name        = "alb-sg-${var.environment}"
  description = "Allow HTTP from internet"
  vpc_id      = aws_vpc.this.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "alb-sg-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_security_group" "ec2" {
  name        = "ec2-sg-${var.environment}"
  description = "Allow traffic only from ALB"
  vpc_id      = aws_vpc.this.id

  # App traffic from ALB only
  ingress {
    from_port       = 1337
    to_port         = 1337
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # SSH from your IP only
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "ec2-sg-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_key_pair" "this" {
  key_name   = var.key_pair_name
  public_key = file("/id_rsa.pub")

  tags = {
    Name        = "strapi-key-${var.environment}"
    Environment = var.environment
  }
}

locals {
  ec2_user_data = <<-EOF
    #!/bin/bash
    yum update -y
    amazon-linux-extras install docker -y
    systemctl start docker
    systemctl enable docker
    usermod -aG docker ec2-user
  EOF
}

resource "aws_instance" "strapi" {
  ami                         = "ami-0532be01f26a3de55" # Amazon Linux 2 (ap-south-1)
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.private[0].id
  vpc_security_group_ids      = [aws_security_group.ec2.id]
  key_name                    = aws_key_pair.this.key_name
  associate_public_ip_address = false
  user_data                   = local.ec2_user_data

  tags = {
    Name        = "strapi-ec2-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_lb_target_group" "strapi" {
  name        = "strapi-tg-${var.environment}"
  port        = 1337
  protocol    = "HTTP"
  vpc_id      = aws_vpc.this.id
  target_type = "instance"

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200-399"
  }

  tags = {
    Name        = "strapi-tg-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_lb_target_group_attachment" "strapi" {
  target_group_arn = aws_lb_target_group.strapi.arn
  target_id        = aws_instance.strapi.id
  port             = 1337
}

resource "aws_lb" "this" {
  name               = "strapi-alb-${var.environment}"
  load_balancer_type = "application"
  internal           = false
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id

  tags = {
    Name        = "strapi-alb-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.strapi.arn
  }
}

resource "aws_ecr_repository" "strapi" {
  name                 = "${var.ecr_repo_name}-${var.environment}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = "strapi-ecr-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_ecr_lifecycle_policy" "strapi" {
  repository = aws_ecr_repository.strapi.name

  policy = <<EOF
  {
  "rules": [
    {
      "rulePriority": 1,
      "description": "Keep last 5 images",
      "selection": {
        "tagStatus": "any",
        "countType": "imageCountMoreThan",
        "countNumber": 5
      },
      "action": {
        "type": "expire"
      }
    }
  ]
}
EOF
}
