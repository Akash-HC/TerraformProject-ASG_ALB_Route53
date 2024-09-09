# create vpc
resource "aws_vpc" "my-vpc" {
    cidr_block = var.vpc_cidr
    enable_dns_hostnames = true
    enable_dns_support = true
    tags = {
        Name = "Terraform-ALB_ASG-vpc"
    }
}

# Map subnet cidr with az
locals {
  Public_subnet_az_map = zipmap(var.Public_subnet_cidr, var.aws_az)
  Private_subnet_az_map = zipmap(var.Private_subnet_cidr, var.aws_az)
}

#create public subnets
resource "aws_subnet" "public-subnet" {
  for_each = local.Public_subnet_az_map
  vpc_id = aws_vpc.my-vpc.id
  cidr_block = each.key
  availability_zone = each.value
  map_public_ip_on_launch = true
  tags = {
    Name = "Terraform-ALB-ASG-PublicSubnet-${each.value}"
  }
}
#create private subnets
resource "aws_subnet" "private-subnet" {
  for_each = local.Private_subnet_az_map
  vpc_id = aws_vpc.my-vpc.id
  cidr_block = each.key
  availability_zone = each.value
  map_public_ip_on_launch = false
  tags = {
    Name = "Terraform-ALB-ASG-PrivateSubnet-${each.value}"
  }
}

# create Elastic Ips for NAT gateway
resource "aws_eip" "my-eip" {
  domain = "vpc"
  count = length(var.aws_az)
  tags = {
    Name = "Terraform-ALB-ASG-EIP"
  }
}

# Create NAT gateway
resource "aws_nat_gateway" "my-NAT" {
  count = length(var.aws_az)
  allocation_id = aws_eip.my-eip[count.index].id
  subnet_id = values(aws_subnet.public-subnet)[count.index].id
  tags = {
    Name = "Terraform-ALB-ASG-NAT"
  }
}

# Create a route table for private subnet
resource "aws_route_table" "my-rt-NAT" {
  vpc_id = aws_vpc.my-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.my-NAT[0].id
  }
  tags = {
    Name = "Terraform-ALB-ASG-RT"
  }
}

# Associate the private route table to private subents 
resource "aws_route_table_association" "private-association" {
  for_each = local.Private_subnet_az_map

  subnet_id = aws_subnet.private-subnet[each.key].id 
  route_table_id = aws_route_table.my-rt-NAT.id
}

# create an IGW
resource "aws_internet_gateway" "my-IGW" {
  vpc_id = aws_vpc.my-vpc.id
  tags = {
    Name = "Terraform-ALB-ASG-IGW"
  }
}

# Create a route table
resource "aws_route_table" "my-rt-IGW" {
    vpc_id = aws_vpc.my-vpc.id
    tags = {
      Name = "Terraform-ALB-ASG-RT"
    }
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.my-IGW.id
    }
}

# Associate the route table
resource "aws_route_table_association" "rt-association" {
  for_each = local.Public_subnet_az_map

  subnet_id = aws_subnet.public-subnet[each.key].id 
  route_table_id = aws_route_table.my-rt-IGW.id
}

# Create security groups for the instance only alb can access the instance at any port
resource "aws_security_group" "my-sg" {
    vpc_id = aws_vpc.my-vpc.id

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        security_groups = [aws_security_group.ALB-sg.id] # add security groups instead of cidr_blocks 
    }
    
    egress {
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = ["0.0.0.0/0"]
    }
}

#create a security group for ALB
resource "aws_security_group" "ALB-sg" {
  vpc_id = aws_vpc.my-vpc.id

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#create a key pair for the template
resource "aws_key_pair" "my-key" {
  key_name = "Terraform-ALB-ASG-key"
  public_key = file("/home/akash/.ssh/id_rsa.pub") 
}


# create a target group for the load balancer
resource "aws_lb_target_group" "my-alb-tg" {
  name = "terraform-alb-asg-target-group"
  port = 80
  protocol = "HTTP"
  vpc_id = aws_vpc.my-vpc.id

  health_check {
    interval = 30
    path = "/"
    protocol = "HTTP"
    timeout = 5
    healthy_threshold = 3
    unhealthy_threshold = 3
  }
}

# create ALB 
resource "aws_lb" "my-ALB" {
  internal = false
  name = "Terraform-ASG-ALB"
  load_balancer_type = "application"
  security_groups = [aws_security_group.ALB-sg.id]
  subnets = values(aws_subnet.public-subnet)[*].id 
}

# specify the listener for the load balancer
resource "aws_lb_listener" "my-listener" {
  load_balancer_arn = aws_lb.my-ALB.id
  port = "80"
  protocol = "HTTP"
  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.my-alb-tg.arn
  }
}

#create a launch template for the asg
resource "aws_launch_template" "my-launch-template" {
  name_prefix = "Terraform-ASG-ALB-template"
  image_id = data.aws_ami.my-ami.id
  instance_type = var.instance_type
  key_name = aws_key_pair.my-key.key_name
  user_data = base64encode(<<-EOF
              #!/bin/bash
              #update the terminal
              sudo apt-get update -y 
              # change to the root directory, because sometimes echo to var file will not succeed
              sudo su 
              cd /
              # Install nginx webserver
              apt-get install nginx -y
              apt-get update 
              # write the index.html file from local to the instance
              echo '${file("/home/akash/index.html")}' | sudo tee /var/www/html/index.html 
              # file () function is used in terraform to copy the file from local to the instance
              # restart and enable the nginx
              systemctl restart nginx
              systemctl enable nginx
              EOF
  )  # Terraform expects to be base64 encoded or else it might throw error sometimes

  tags = {
    Name = "Terraform-ALB-ASG-instance"
  }
  #add security groups to the instances
  network_interfaces {
    security_groups = [aws_security_group.my-sg.id]
  }
}

# create a auto scaling group 
resource "aws_autoscaling_group" "my-asg" {
  desired_capacity = 1
  min_size = 1
  max_size = 4
  vpc_zone_identifier = values(aws_subnet.private-subnet)[*].id
  launch_template {
    id = aws_launch_template.my-launch-template.id
    version = "$Latest"
  }

  # Attach the ASG to target group
  target_group_arns = [aws_lb_target_group.my-alb-tg.arn]

  #Health checks for the instances
  health_check_type = "EC2"
  health_check_grace_period = 300

  tag {
    key = "Name"
    value = "app-instance"
    propagate_at_launch = true
  }
} 

# create an automatic scaling policy for the asg
resource "aws_autoscaling_policy" "my-scaling-policy" {
  name = "CPU_target_tracking"
  policy_type = "TargetTrackingScaling"
  autoscaling_group_name = aws_autoscaling_group.my-asg.name

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 50.0 # Maintain CPU utilization at 50%
  }
} 

# Create a alias record for the alb dns
resource "aws_route53_record" "alb-record" {
  zone_id = data.aws_route53_zone.devopsify-zone.zone_id
  name = "test.devopsify.xyz"
  type = "A"

  alias {
    name = aws_lb.my-ALB.dns_name
    zone_id = aws_lb.my-ALB.zone_id # Use the alb's zone id for the alias record
    evaluate_target_health = true # enables the health check evaluation
  }
}
