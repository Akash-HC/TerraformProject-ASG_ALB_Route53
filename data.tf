# retrieve the information related to the ubuntu ami id
data "aws_ami" "my-ami" {
    owners = ["099720109477"]
    most_recent = true
    filter {
      name = "name"
      values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
    }
}

# retrieve the information of the already created route53 public hosted zone
data "aws_route53_zone" "devopsify-zone" {
  name = "devopsify.xyz"
  private_zone = false
}