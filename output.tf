# customize based on requirements
# Output the DNS name of the Application Load Balancer
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.my-ALB.dns_name
}

# Output the ALB Target Group ARN
output "alb_target_group_arn" {
  description = "ARN of the ALB Target Group"
  value       = aws_lb_target_group.my-alb-tg.arn
}

# Output the Auto Scaling Group name
output "asg_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.my-asg.name
}

# Output the Launch Template ID
output "launch_template_id" {
  description = "Launch Template ID"
  value       = aws_launch_template.my-launch-template.id
}

# output the alias url 
output "alias_url" {
  value = "http://test.devopsify.xyz"  # Replace with your desired subdomain or root domain
}


# Output the Load Balancer Security Group ID
output "alb_security_group_id" {
  description = "ID of the Security Group for the ALB"
  value       = aws_security_group.ALB-sg.id
}

# Output the Subnet IDs used for the Auto Scaling Group
output "subnet_ids" {
  description = "Subnet IDs for the Auto Scaling Group instances"
  value       = values(aws_subnet.public-subnet)[*].id
}
