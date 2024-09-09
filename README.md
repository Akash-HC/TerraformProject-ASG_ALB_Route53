# TerraformProject-ASG_ALB_Route53
This repository contains a Terraform configuration for deploying and managing a scalable web application on AWS. The project demonstrates how to set up an Auto Scaling Group (ASG) to handle varying levels of web traffic, an Application Load Balancer (ALB) to distribute incoming requests, and Route 53 for DNS management.

# AWS Web Page Deployment with ASG, ALB, and Route 53

## Overview

This repository provides Terraform configuration files to deploy and manage a scalable web application on AWS. The setup includes an Auto Scaling Group (ASG) to handle fluctuating web traffic, an Application Load Balancer (ALB) to distribute incoming requests, and Route 53 for DNS management. A sample static web page is used to demonstrate the deployment and scaling capabilities.

## Architecture

- **EC2 Instances:** Managed by an Auto Scaling Group to ensure high availability and scalability based on traffic demands.
- **Application Load Balancer (ALB):** Distributes HTTP/HTTPS requests to multiple EC2 instances to balance the load and enhance reliability.
- **Route 53:** Configures DNS to route traffic to the ALB, allowing users to access the web page via a custom domain.

## Features

- **Auto Scaling Group (ASG):** Automatically scales the number of EC2 instances up or down based on defined policies.
- **Application Load Balancer (ALB):** Distributes incoming traffic evenly across EC2 instances.
- **Route 53:** Manages DNS records to point to the ALB, providing a user-friendly domain name.
- **Sample Web Page:** Deploys a basic HTML page to demonstrate the setup.![TerraformProject-ASG_ALB-Infra](https://github.com/user-attachments/assets/fe7bbd61-85ed-4370-8864-8fc561a8b2c7)
