## VPC ##
resource "aws_vpc" "main" {
    cidr_block           = "10.0.0.0/16"
    enable_dns_support   = true
    enable_dns_hostnames = true
    tags = {
        Name = "strapi-vpc-${var.env}"
    }
}

## Public Subnet ##
resource "aws_subnet" "public" {
    vpc_id                     = aws_vpc.main.id
    cidr_block                 = "10.0.1.0/24"
    availability_zone          = var.az
    map_public_ip_on_launch    = true

    tags = {
        Name = "public-subnet-${var.env}"
    }
}

## Public Subnet 2 ##
resource "aws_subnet" "public_2" {
    vpc_id                     = aws_vpc.main.id
    cidr_block                 = "10.0.3.0/24"
    availability_zone          = var.az_2
    map_public_ip_on_launch    = true

    tags = {
        Name = "public-subnet-2-${var.env}"
    }
}

## Private Subnet ##
resource "aws_subnet" "private" {
    vpc_id              = aws_vpc.main.id
    cidr_block          = "10.0.2.0/24"
    availability_zone   = var.az

    tags ={
        Name = "private-subnet-${var.env}"
    } 
}

## Internet Gateway ##
resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.main.id

    tags = {
        Name = "igw-${var.env}"
    }
}

## Public Route Table ##
resource "aws_route_table" "public" {
    vpc_id  =  aws_vpc.main.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw.id
    }

    tags = {
        Name = "public-rt-${var.env}"
    }
}

resource "aws_route_table_association" "public_assoc" {
    subnet_id      = aws_subnet.public.id
    route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_assoc_2" {
    subnet_id      = aws_subnet.public_2.id
    route_table_id = aws_route_table.public.id
}

## ElasticIp for NAT Gateway ##
resource "aws_eip" "nat_eip" {
    domain = "vpc"
    tags = {
        Name  = "nat-eip-${var.env}"
    }
}

## NAT Gateway ##
resource "aws_nat_gateway" "nat" {
    allocation_id   = aws_eip.nat_eip.id
    subnet_id       = aws_subnet.public.id

    tags = {
        Name = "nat-gateway-${var.env}"
    }
}

## Private Route Table ##
resource "aws_route_table" "private" {
    vpc_id = aws_vpc.main.id

    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.nat.id
    }

    tags = {
        Name = "private-rt-${var.env}"
    }
}

resource "aws_route_table_association" "private_assoc" {
    subnet_id      = aws_subnet.private.id
    route_table_id = aws_route_table.private.id
}

## Security Group - Load Balancer ##
resource "aws_security_group" "alb_sg" {
    name    = "alb-sg-${var.env}"
    description = "Allow HTTP access from internet"
    vpc_id  = aws_vpc.main.id

    ingress {
        description = "HTTP From Internet"
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

## Security Group - Private EC2 ##
resource "aws_security_group" "ec2_sg" {
    name = "ec2-sg-${var.env}"
    description = "Allow traffic only from ALB"
    vpc_id = aws_vpc.main.id

    ingress {
        description     = "Strapi traffic from ALB only"
        from_port       = 1337
        to_port         = 1337
        protocol        = "tcp"
        security_groups = [aws_security_group.alb_sg.id]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

## Key Pair ##
resource "aws_key_pair" "strapi_key" {
    key_name = "strapi-key-${var.env}"
    public_key = file(var.public_key_path)
}

## Private EC2 with Strapi ##
resource "aws_instance" "strapi_ec2" {
    ami = var.ami_id
    instance_type = var.instance_type
    key_name = aws_key_pair.strapi_key.key_name
    iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
    subnet_id  = aws_subnet.private.id
    vpc_security_group_ids = [aws_security_group.ec2_sg.id]

    associate_public_ip_address = false

    user_data = file("${path.module}/user_data.sh")

    tags = {
        Name = "strapi-ec2-${var.env}"
    }
}

## Application Load Balancer ##
resource "aws_lb" "alb" {
    name = "strapi-alb-${var.env}"
    load_balancer_type = "application"

    subnets = [
        aws_subnet.public.id,
        aws_subnet.public_2.id
    ]
    security_groups = [aws_security_group.alb_sg.id]

    tags = {
        Name = "strapi-alb-${var.env}"
    }
}

## Target Group ##
resource "aws_lb_target_group" "strapi_tg" {
    name = "strapi-tg-${var.env}"
    port = 1337
    protocol = "HTTP"
    vpc_id = aws_vpc.main.id

    health_check {
        path = "/admin"
        protocol = "HTTP"
        port = "1337"
        healthy_threshold = 2
        unhealthy_threshold = 2
        timeout = 5
        interval = 30
    }

    tags = {
        Name = "strapi-tg-${var.env}"
    }
}

## Register EC2 with Target Group ##
resource "aws_lb_target_group_attachment" "strapi_attach" {
    target_group_arn = aws_lb_target_group.strapi_tg.arn
    target_id = aws_instance.strapi_ec2.id
    port = 1337
} 

## ALB Listner ##
resource "aws_lb_listener" "http_listener" {
    load_balancer_arn = aws_lb.alb.arn
    port = 80
    protocol = "HTTP"

    default_action {
        type = "forward"
        target_group_arn = aws_lb_target_group.strapi_tg.arn
    }
}

## ECR Repository for Strapi Image ##
resource "aws_ecr_repository" "strapi" {
    name = "strapi-app"
    image_tag_mutability = "MUTABLE"
    
    image_scanning_configuration {
        scan_on_push = true
    }

    tags = {
        Name ="strapi-ecr-${var.env}"
    }
}

## IAM Role for EC2 to access ECR ##
resource "aws_iam_role" "ec2_ecr_role" {
  name = "ec2-ecr-role-${var.env}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

## Attach ECR Read-Only Policy ##
resource "aws_iam_role_policy_attachment" "ecr_read" {
  role       = aws_iam_role.ec2_ecr_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

## IAM Instance Profile ##
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-profile-${var.env}"
  role = aws_iam_role.ec2_ecr_role.name
}