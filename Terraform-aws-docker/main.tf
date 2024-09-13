# specify the provider
provider "aws" {
  region = "us-east-1"
}

# create a data block for a template file for the outputs if you want to use ansible for further configuration management
# or else you can skip this part
# It will update the inventory for the ansible scripts with the template and values mentioned
# You can also customize the template

data "template_file" "inventory" {
    template = <<-EOF
        [private_instance]
        ec2-instance ansible_host=$${private_ip} ansible_user=ubuntu ansible_ssh_private_key_file=/home/akash/New_key2.pem

        [bastion_host]
        ec2-instance ansible_host=$${public_dns} ansible_user=ubuntu ansible_ssh_private_key_file=/home/akash/New_key.pem
    EOF 

    vars = {
        public_dns = aws_instance.bastion.public_dns
        public_ip = aws_instance.bastion.public_ip
        private_dns = aws_instance.private.private_dns
        private_ip = aws_instance.private.private_ip
    }   
}

# retrieve data form ubuntu image
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

# retrieve the route53 hosted zone data
data "aws_route53_zone" "devopsify-zone" {
  name = "devopsify.xyz"
  private_zone = false
}

# Declare the variables if any
variable "public_subnet_cidr" {
  type = list(string)
  default = [ "10.5.1.0/24", "10.5.2.0/24" ]
}

variable "private_subnet_cidr" {
  type = list(string)
  default = [ "10.5.3.0/24", "10.5.4.0/24" ]
}

variable "az" {
  type = list(string)
  default = ["us-east-1a", "us-east-1c"]
}

# create vpc
resource "aws_vpc" "vpc" {
  cidr_block           = "10.5.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "k8s-vpc"
  }
}

# create a zipmap so that each subnet cidr is mapped to an az
locals {
  public_subnet_az_map = zipmap(var.public_subnet_cidr, var.az)
  private_subnet_az_map = zipmap(var.private_subnet_cidr, var.az)
}

# create public subnets
resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidr)
  vpc_id = aws_vpc.vpc.id
  cidr_block = var.public_subnet_cidr[count.index]
  availability_zone = local.public_subnet_az_map[var.public_subnet_cidr[count.index]]
  map_public_ip_on_launch = true
  tags = {
    Name = "k8s-public-subnet-${count.index}"
  }
}

# create private subnets
resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidr)
  vpc_id = aws_vpc.vpc.id
  cidr_block = var.private_subnet_cidr[count.index]
  availability_zone = local.private_subnet_az_map[var.private_subnet_cidr[count.index]]
  tags = {
    Name = "k8s-private-subnet-${count.index}"
  }
}

# create internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "k8s-igw"
  }
}

# create NAT gateway
resource "aws_eip" "nat" {
  domain = "vpc"

}
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id = aws_subnet.public[0].id
  tags = {
    Name = "k8s-nat"
  }
}

# create public route table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "k8s-public-rt"
  }
}

# create private route table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat.id
  }
  tags = {
    Name = "k8s-private-rt"
  }
}

# associate public subnets with public route table
resource "aws_route_table_association" "public" {
  count = length(var.public_subnet_cidr)
  subnet_id = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# associate private subnets with private route table
resource "aws_route_table_association" "private" {
  count = length(var.private_subnet_cidr)
  subnet_id = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# create security group for public subent and ALB
resource "aws_security_group" "public" {
  name = "k8s-public-sg"
  vpc_id = aws_vpc.vpc.id
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
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# create a security group for private subnets and allow http traffic only from ALB sg
resource "aws_security_group" "private" {
  name = "k8s-private-sg"
  vpc_id = aws_vpc.vpc.id
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
    security_groups = [aws_security_group.public.id]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# create a security group for bastion host
resource "aws_security_group" "bastion" {
  name = "k8s-bastion-sg"
  vpc_id = aws_vpc.vpc.id
  ingress {
    from_port = 22
    to_port = 22
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

# create an application load balancer
resource "aws_lb" "alb" {
  name = "k8s-alb"
  internal = false
  load_balancer_type = "application"
  security_groups = [aws_security_group.public.id]
  subnets = aws_subnet.public[*].id
}

# create a target group for ALB
resource "aws_lb_target_group" "alb" {
  name = "k8s-alb-tg"
  port = 80
  protocol = "HTTP"
  vpc_id = aws_vpc.vpc.id

  health_check {
    interval = 30
    path = "/" # if you use kubernetes for further enhancements, then it should be modified 
    port = 80
    protocol = "HTTP"
    timeout = 5
    healthy_threshold = 3
    unhealthy_threshold = 3
  }
} 

# create a listener for ALB
resource "aws_lb_listener" "alb" {
  load_balancer_arn = aws_lb.alb.arn
  port = 80
  protocol = "HTTP"
  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.alb.arn
  }
}

# create a bastion host in public subnet
resource "aws_instance" "bastion" {
  ami = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  subnet_id = aws_subnet.public[0].id 
  vpc_security_group_ids = [aws_security_group.bastion.id]
  key_name = "New_key2"
  associate_public_ip_address = true

  tags = {
    Name = "Bastion"
  }
}

# create an ec2 instance in private subnet
resource "aws_instance" "private" {
  ami = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  subnet_id = aws_subnet.private[0].id
  vpc_security_group_ids = [aws_security_group.private.id]
  key_name = "New_key2"

  provisioner "remote-exec" {
    inline = [
      "sleep 30", # Give the instance time to fully initialize
      "sudo apt-get update -y",
      "sudo apt-get install -y docker.io",
      "sudo systemctl start docker",
      "sudo systemctl enable docker",
      "sudo usermod -aG docker ubuntu",
      "sudo docker pull akashhc55/web-build:v1", #You can create your own image or you can use this image as well
      "sudo docker run -d -p 80:80 akashhc55/web-build:v1"
    ]
    connection {
      type = "ssh"
      user = "ubuntu"
      private_key = file("/path/to/keyfile/in/local") #specify the private key file path 
      host = self.private_ip
      bastion_host = aws_instance.bastion.public_ip
      bastion_user = "ubuntu"
      bastion_private_key = file("/path/to/keyfile/in/local")
    }
  }
  tags = {
    Name = "k8s-private-ec2"
  }
}

# Associate the instance to the target group
resource "aws_lb_target_group_attachment" "alb" {
  target_group_arn = aws_lb_target_group.alb.arn
  target_id = aws_instance.private.id
  port = 80
}

# create an alias record in route53 hosted zone for alb
resource "aws_route53_record" "alb-record" {
  zone_id = data.aws_route53_zone.devopsify-zone.zone_id
  name = "test.example.com" # your domain name
  type = "A"

  alias {
    name = aws_lb.alb.dns_name
    zone_id = aws_lb.alb.zone_id # Use the alb's zone id for the alias record
    evaluate_target_health = true # enables the health check evaluation
  }
}

# output files
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.alb.dns_name
}

output "bastion_dns_name" {
  description = "DNS of the bastion"
  value = aws_instance.bastion.public_dns
}

output "bastion_ip" {
  description = "Bastion public ip"
  value = aws_instance.bastion.public_ip
}

output "instance_ip" {
  description = "private ip of the instance"
  value = aws_instance.private.private_ip
}

output "url" {
  description = "Route53 url"
  value = "http://test.example.com" # your url for the domain
}

# create a local file for the inventory and update
# As mentioned earlier, if you do not want to use ansible then you can skip this as well
# It will create/update the inventory file in local with the template and values from the data block mentioned in the script

resource "local_file" "ansible_inventory" {
  content = data.template_file.inventory.rendered
  filename = "inventory"
  depends_on = [aws_instance.private, aws_instance.bastion]
} 
