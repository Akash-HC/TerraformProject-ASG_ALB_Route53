variable "vpc_cidr" {
    description = "provide the cidr value"
    type = string
    default = "10.3.0.0/16"
}

variable "Public_subnet_cidr" {
    description = "provide the subnet cidr"
    type = list(string)
    default = [ "10.3.1.0/24", "10.3.2.0/24" ]
}

variable "Private_subnet_cidr" {
    description = "provide the subnet cidr"
    type = list(string)
    default = [ "10.3.3.0/24", "10.3.4.0/24" ]
} 

variable "aws_az" {
    description = "specify availability zones"
    type = list(string)
    default = [ "us-east-1a", "us-east-1c" ]
}

variable "instance_type" {
    description = "specify the instance type"
    type = string
    default = "t2.micro"
}
