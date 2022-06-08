terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "4.14.0"
        }
    }
}

# Declare variables

variable "region" {
    description = "The region to deploy the application"
    default = "us-east-1"
}

variable "db_username" {
    description = "The username to be used for database access"
}

variable "db_password" {
    description = "The password to be used for database access"
}

variable "key_name" {
    description = "The SSK key used to access instances"
}

# Configure AWS provider

provider "aws" {
    profile = "default"
    region = var.region 
}

# Store SSM parameters

resource "aws_ssm_parameter" "spring_boot_rest_api_db_username" {
    name  = "spring-boot-rest-api-db-username"
    type  = "String"
    value = var.db_username
}

resource "aws_ssm_parameter" "spring_boot_rest_api_db_password" {
    name  = "spring-boot-rest-api-db-password"
    type  = "String"
    value = var.db_password
}

resource "aws_vpc" "vpc" {
    cidr_block = "10.0.0.0/16"
    enable_dns_support = true
    enable_dns_hostnames = true

    tags = {
        Name = "Spring boot API VPC"
    }
}

resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.vpc.id

    tags = {
        Name = "Spring boot API IGW"
    }
}

resource "aws_subnet" "public_subnet_1" {
    availability_zone = "us-west-2a"
    cidr_block = "10.0.1.0/24"
    map_public_ip_on_launch = true
    vpc_id = aws_vpc.vpc.id

    tags = {
        Name = "Public Subnet 1"
    }
}

resource "aws_subnet" "public_subnet_2" {
    availability_zone = "us-west-2b"
    cidr_block = "10.0.2.0/24"
    map_public_ip_on_launch = true
    vpc_id = aws_vpc.vpc.id

    tags = {
        Name = "Public Subnet 2"
    }
}

resource "aws_subnet" "private_subnet_1" {
    availability_zone = "us-west-2a"
    cidr_block = "10.0.3.0/24"
    map_public_ip_on_launch = false 
    vpc_id = aws_vpc.vpc.id

    tags = {
        Name = "Private Subnet 1"
    }
}

resource "aws_subnet" "private_subnet_2" {
    availability_zone = "us-west-2b"
    cidr_block = "10.0.4.0/24"
    map_public_ip_on_launch = false 
    vpc_id = aws_vpc.vpc.id

    tags = {
        Name = "Private Subnet 2"
    }
}

resource "aws_subnet" "private_subnet_3" {
    availability_zone = "us-west-2a"
    cidr_block = "10.0.5.0/24"
    map_public_ip_on_launch = false 
    vpc_id = aws_vpc.vpc.id

    tags = {
        Name = "Private Subnet 3"
    }
}

resource "aws_subnet" "private_subnet_4" {
    availability_zone = "us-west-2b"
    cidr_block = "10.0.6.0/24"
    map_public_ip_on_launch = false 
    vpc_id = aws_vpc.vpc.id

    tags = {
        Name = "Private Subnet 4"
    }
}
resource "aws_route_table" "public_route_table" {
    vpc_id = aws_vpc.vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw.id
    }

    tags = {
        Name = "Public Route Table"
    }
}

resource "aws_route_table_association" "public_subnet1_rt_assoc" {
    subnet_id = aws_subnet.public_subnet_1.id
    route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_subnet2_rt_assoc" {
    subnet_id = aws_subnet.public_subnet_2.id
    route_table_id = aws_route_table.public_route_table.id
}

resource "aws_security_group" "elb_sg" {
    name = "elb_sg"
    vpc_id = aws_vpc.vpc.id

    ingress {
        description = "allow HTTP connections from the internet"
        protocol = "tcp"
        from_port = 80 
        to_port = 80 
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "ELB-Security-Group"
    }
}

resource "aws_security_group" "bastion_sg" {
    name = "bastion_sg"
    vpc_id = aws_vpc.vpc.id

    ingress {
        description = "allow SSH connections from the internet"
        protocol = "tcp"
        from_port = 22 
        to_port = 22 
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "Bastion Host Security Group"
    }
}

resource "aws_security_group" "webservers_sg" {
    name = "webservers_sg"
    vpc_id = aws_vpc.vpc.id

    ingress {
        description = "allow HTTP connections from the ELB"
        protocol = "tcp"
        from_port = 80
        to_port = 80
        security_groups = [aws_security_group.elb_sg.id]
    }

    ingress {
        description = "allow SSH from the bastion host"
        protocol = "tcp"
        from_port = 22
        to_port = 22
        security_groups = [aws_security_group.bastion_sg.id]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "Webservers Security Group"
    }
}

resource "aws_security_group" "db_sg" {
    name = "db_sg"
    vpc_id = aws_vpc.vpc.id

    ingress {
        description = "allow webservers group to connect to postgresql"
        protocol = "tcp"
        from_port = 5432 
        to_port = 5432 
        security_groups = [aws_security_group.webservers_sg.id]
    }

    tags = {
        Name = "Databases Security Group"
    }
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

data "aws_iam_policy_document" "instance-assume-role-policy" {
    statement {
        actions = ["sts:AssumeRole"]

        principals {
            type        = "Service"
            identifiers = ["ec2.amazonaws.com"]
        }
    }
}

resource "aws_iam_role" "instance_role" {
    name               = "instance-role"
    assume_role_policy = data.aws_iam_policy_document.instance-assume-role-policy.json

    inline_policy {
        name = "s3_read_only_policy"

        policy = jsonencode({
            Version = "2012-10-17"
            Statement = [
                {
                    Action   = ["s3:Get*", "s3:DescribeObject", "s3:List*", "s3-object-lambda:Get*", "s3-object-lambda:List*" ]
                    Effect   = "Allow"
                    Resource = "*"
                },
            ]
        })
    }
}

resource "aws_instance" "bastion_host" {
    ami = data.aws_ami.ubuntu.id
    associate_public_ip_address = true
    instance_type = "t2.micro"
    key_name = var.key_name 
    subnet_id = aws_subnet.public_subnet_1.id
    vpc_security_group_ids = [ aws_security_group.bastion_sg.id ]

    tags = {
        Name = "Spring-boot API Bastion Host"
    }
}

resource "aws_launch_template" "webservers_template" {
    name = "server-template"

    iam_instance_profile {
        name = "instance-role"
    }

    image_id = "ami-0cb4e786f15603b0d"
    instance_type = "t2.micro"
    key_name = var.key_name 
    vpc_security_group_ids = [ aws_security_group.webservers_sg.id ] 

    tag_specifications {
        resource_type = "instance"

        tags = {
            Name = "spring-boot-rest-api-tutorial"
        }
    }
}

resource "aws_lb_target_group" "autoscaling_tg" {
    name     = "autoscaling-tg"
    port     = 80
    protocol = "HTTP"
    vpc_id   = aws_vpc.vpc.id
}

resource "aws_autoscaling_group" "webservers_asg" {
    name = "webservers-asg"
    desired_capacity   = 2
    max_size           = 6
    min_size           = 2
    target_group_arns = [ aws_lb_target_group.autoscaling_tg.arn ]
    vpc_zone_identifier = [ aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id ]

    launch_template {
        id      = aws_launch_template.webservers_template.id
        version = "$Latest"
    }
}

resource "aws_autoscaling_policy" "cpu_usage_policy" {
    name                   = "cpu_usage_policy"
    autoscaling_group_name = aws_autoscaling_group.webservers_asg.name
    adjustment_type        = "ChangeInCapacity"
    cooldown               = 300
    policy_type = "TargetTrackingScaling"

    target_tracking_configuration {
        predefined_metric_specification {
            predefined_metric_type = "ASGAverageCPUUtilization"
        }
        target_value = 40.0
    }
}

resource "aws_lb" "webservers_elb" {
    name               = "webservers-elb"
    internal           = false
    load_balancer_type = "application"
    security_groups    = [ aws_security_group.elb_sg.id ]
    #subnets            = [ for subnet in aws_subnet.public : subnet.id ]
    subnets            = [ aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id ]
}

resource "aws_lb_listener" "back_end" {
    load_balancer_arn = aws_lb.webservers_elb.arn
    port              = "80"
    protocol          = "HTTP"

    default_action {
        type             = "forward"
        target_group_arn = aws_lb_target_group.autoscaling_tg.arn
    }
}

resource "aws_db_subnet_group" "db_subnet_group" {
    name       = "db-subnet-group"
    subnet_ids = [ aws_subnet.private_subnet_3.id, aws_subnet.private_subnet_4.id ]

    tags = {
        Name = "My DB subnet group"
    }
}

resource "aws_db_instance" "api_db" {
    allocated_storage    = 10
    db_name              = "taskmanagerdb"
    db_subnet_group_name = aws_db_subnet_group.db_subnet_group.name
    engine               = "postgres"
    engine_version       = "13.6"
    instance_class       = "db.t3.micro"
    multi_az = false
    username             = "ubuntu"
    password             = "password"
    port = 5432
    skip_final_snapshot  = true
    vpc_security_group_ids = [ aws_security_group.db_sg.id ]
}

resource "aws_ssm_parameter" "sprint_boot_rest_api_db_host" {
    name  = "spring-boot-rest-api-db-host"
    type  = "String"
    value = aws_db_instance.api_db.endpoint
}

output "elb_endpoint" {
    value = aws_lb.elb.webservers_elb.dns_name
}