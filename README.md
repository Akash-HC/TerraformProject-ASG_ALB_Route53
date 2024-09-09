# Web hosting with AWS ASG, ALB, and Route 53 using Terraform

## Overview

This repository provides Terraform configuration files to deploy and manage a scalable web application on AWS. The setup includes an Auto Scaling Group (ASG) to handle fluctuating web traffic, an Application Load Balancer (ALB) to distribute incoming requests, and Route 53 for DNS management. A sample static web page is used to demonstrate the deployment and scaling capabilities.

## Architecture

- **EC2 Instances:** Managed by an Auto Scaling Group to ensure high availability and scalability based on traffic demands.
- **Application Load Balancer (ALB):** Distributes HTTP/HTTPS requests to multiple EC2 instances to balance the load and enhance reliability.
- **Route 53:** Configures DNS to route traffic to the ALB, allowing users to access the web page via a custom domain.

  
![TerraformProject-ASG_ALB-Infra](https://github.com/user-attachments/assets/ae7454be-11f0-4243-9aa3-d947dd4593d2)



## Features

- **Auto Scaling Group (ASG):** Automatically scales the number of EC2 instances up or down based on defined policies.
- **Application Load Balancer (ALB):** Distributes incoming traffic evenly across EC2 instances.
- **Route 53:** Manages DNS records to point to the ALB, providing a user-friendly domain name.
- **Sample Web Page:** Deploys a basic HTML page to demonstrate the setup.!
