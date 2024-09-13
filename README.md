****Web Page Hosting with Docker, EC2, and Terraform****

This project automates the deployment of a web application hosted inside a Docker container on an EC2 instance in AWS. The infrastructure is set up using a single, non-modular Terraform script. The deployment also integrates an Application Load Balancer (ALB) for load distribution and uses Route 53 to make the application publicly accessible via a custom domain.

**Project Overview**

The goal of this project is to demonstrate how to build a fully automated, scalable, and publicly accessible web application hosted on AWS. Terraform is used to provision the entire infrastructure, eliminating the need for manual setup. The web page is served from a Docker container running on an EC2 instance, which is fronted by a Load Balancer and accessible through a domain registered in Route 53.

**Key Components:**

  - Docker Container: Hosts the web page (e.g., index.html) served via a lightweight web server (e.g., Nginx).
  - EC2 Instance: Runs the Docker container in a secure AWS environment.
  - Application Load Balancer (ALB): Distributes traffic across EC2 instances, ensuring scalability and availability.
  - Route 53 DNS: Provides a publicly accessible domain name for the application, routing traffic to the ALB.
  - Terraform: Automates the infrastructure deployment, configuring all AWS resources in a single script.

**Objectives**

  - Automated Infrastructure: Use Terraform to define and provision all necessary AWS resources, including VPC, subnets, security     groups, EC2 instances, load balancers, and Route 53 DNS records.
  - Scalability: Ensure the application can scale by integrating an Application Load Balancer to manage incoming traffic and          future resource expansion.
  - Public Accessibility: Map the load balancer to a custom domain using Route 53, making the web page accessible over the            internet.
  - Simplified Deployment: Bundle the entire infrastructure setup and application deployment into a single Terraform script to        streamline the process.

**Achievements**

  - End-to-End Automation: The infrastructure is fully automated, from EC2 instance creation to Docker container deployment,          using a single Terraform script.
  - Scalability and Reliability: By integrating the Application Load Balancer, the architecture can easily scale and handle           multiple instances, ensuring high availability.
  - Domain Integration: Route 53 ensures that the application is accessible via a custom domain, providing a professional and         publicly reachable endpoint.
  - Infrastructure as Code (IaC): The project adopts Terraform as the IaC tool, promoting best practices like version control,        automation, and repeatability in infrastructure management.

**Future Enhancements**

  - SSL/HTTPS Support: Integrate SSL certificates via AWS Certificate Manager (ACM) to serve the application securely over HTTPS.
  - Modular Terraform Design: Refactor the Terraform script into reusable modules for better code organization and scalability.
  - Auto-scaling: Add an auto-scaling policy based on traffic or CPU utilization to further improve resource management and cost      efficiency.
