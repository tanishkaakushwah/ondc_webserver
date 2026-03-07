# Production-Grade Scalable Web Server on AWS using Terraform

## Overview

This project provisions a **production-ready AWS infrastructure using Terraform** to deploy a scalable web server behind an **Application Load Balancer (ALB)**.

The infrastructure follows common cloud best practices such as:

- High availability across multiple Availability Zones
- Network isolation using public and private subnets
- Secure compute infrastructure without public exposure
- Modular Terraform architecture
- Remote Terraform state management with locking
- Basic observability for operational readiness

Only the **Application Load Balancer is internet-facing**, while EC2 instances run securely inside **private subnets**.

---

# Architecture Diagram

                      Internet
                          |
                          v
               +----------------------+
               | Application Load     |
               | Balancer (Public)    |
               +----------+-----------+
                          |
                          v
                 +----------------+
                 |  Target Group  |
                 +-------+--------+
                         |
                         v

     +------------------------------------------+
     |          Auto Scaling Group              |
     |                                          |
     |   +---------------+   +---------------+  |
     |   | EC2 Instance  |   | EC2 Instance  |  |
     |   |   Nginx Web   |   |   Nginx Web   |  |
     |   |   Server      |   |   Server      |  |
     |   | (Private AZ1) |   | (Private AZ2) |  |
     |   +---------------+   +---------------+  |
     |                                          |
     +------------------------------------------+

                  |
                  v
              NAT Gateway
                  |
                  v
           Internet Gateway

#Supporting Services

• CloudWatch (metrics & alarms)
• S3 (Terraform remote state)
• DynamoDB (state locking)
• IAM role for EC2 (SSM access)


---

# Infrastructure Components

## 1. Networking Layer

The network module provisions a **VPC spanning two Availability Zones**.

Resources created:

- VPC
- Public Subnets (2)
- Private Subnets (2)
- Internet Gateway
- NAT Gateway
- Route Tables

### Public Subnets

Used for:

- Application Load Balancer
- NAT Gateway

These subnets route traffic through the **Internet Gateway**.

### Private Subnets

Used for:

- EC2 instances running the application

Instances in these subnets **do not receive public IP addresses**.

Internet access for updates is provided through the **NAT Gateway**.

---

# Compute Layer

The compute layer provisions the application servers.

Resources:

- Launch Template
- Auto Scaling Group
- IAM Instance Role
- Bootstrap User Data Script

### Launch Template

Defines:

- AMI
- Instance type
- Security groups
- Encrypted EBS volume
- IMDSv2 enforcement
- User data configuration

### Auto Scaling Group

The Auto Scaling Group ensures the application remains available and scalable.

Configurable parameters:

- Minimum capacity
- Desired capacity
- Maximum capacity

Scaling is based on **CPU utilization metrics**.

If an instance fails health checks, it is automatically replaced.

---

# EC2 Bootstrap (User Data)

Each EC2 instance installs and starts a simple **Nginx web server**.

```bash
#!/bin/bash

apt update -y
apt install nginx -y

systemctl start nginx
systemctl enable nginx

echo "Hello from ONDC DevOps Assignment" > /var/www/html/index.html
```
Once instances are running, they serve the test page via the ALB.

## Traffic Layer (Application Load Balancer)

The **Application Load Balancer (ALB)** is deployed in **public subnets** and acts as the **entry point for incoming traffic**.

### Resources Created

- Application Load Balancer
- Target Group
- Listener on **port 80**
- Health Checks

### Health Checks

Target group health checks ensure that **traffic is routed only to healthy EC2 instances**.

**Example configuration:**

- **Path:** `/`
- **Interval:** 30 seconds
- **Healthy threshold:** 2
- **Unhealthy threshold:** 3

After deployment, the **application is reachable via the ALB DNS endpoint**.

http://<alb-dns-name>

## Security Design

Security is implemented using **least privilege principles**.

### No Public EC2 Access

- EC2 instances are placed in **private subnets**
- **No public IP addresses** are assigned
- Traffic flows **only through the Application Load Balancer (ALB)**

---

## Security Groups

### ALB Security Group

**Inbound**

- HTTP (80) from `0.0.0.0/0`
- HTTPS (443) from `0.0.0.0/0`

**Outbound**

- All traffic allowed

### EC2 Security Group

**Inbound**

- HTTP (80) **only from ALB Security Group**

**Outbound**

- All traffic allowed

---

## Instance Metadata Protection

**IMDSv2** is enforced to protect instance metadata.

---

## Storage Security

All **EBS volumes are encrypted by default**.

---

## Instance Access

SSH access is **not required**.

Instances are accessed using:

**AWS Systems Manager Session Manager**

### Benefits

- No open SSH ports
- No key pair management
- Fully auditable access

---

## Terraform State Management

Terraform state is stored remotely using:

- **S3 bucket** – state storage
- **DynamoDB table** – state locking

### Example Backend Configuration

```hcl
terraform {
  backend "s3" {
    bucket         = "terraform-ondc-state"
    key            = "prod/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "terraform-lock-table"
  }
}
```

Benefits:

Prevents concurrent state modification
Protects state integrity
Enables team collaboration

## Observability

Basic monitoring is implemented using **CloudWatch**.

### Metrics

- EC2 **CPU Utilization**
- ALB **Request Count**
- **Target Group Health**

### CloudWatch Alarm

**Example Alarm:**

- **Metric:** CPUUtilization  
- **Condition:** > 70%  
- **Duration:** 5 minutes

This helps detect **abnormal load spikes** and potential performance issues.

###Terraform Project Structure
```
terraform-ondc-assignment
│
├── modules
│   ├── network
│   ├── compute
│   ├── alb
│   └── security
│
├── environments
│   ├── dev
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── backend.tf
│   │
│   └── prod
│       ├── main.tf
│       ├── variables.tf
│       └── backend.tf
│
├── scripts
│   └── user_data.sh
│
└── README.md
```
##Deployment Instructions

Initialize Terraform: terraform init

Validate configuration: terraform validate

Format code: terraform fmt

Preview infrastructure changes: terraform plan

Apply infrastructure: terraform apply

Terraform will output the ALB DNS name once deployment is complete.

## Destroy Infrastructure

To remove all resources:

```bash
terraform destroy
```

Assumptions

Region used: ap-south-1

Ubuntu AMI used for EC2 instances

Nginx used as the sample web server

ACM certificate not configured due to lack of domain

## How HTTPS Would Be Implemented

### Steps

1. Request a certificate in **AWS Certificate Manager (ACM)**
2. Validate **domain ownership**
3. Attach the certificate to the **ALB listener on port 443**
4. Redirect **HTTP traffic to HTTPS**

---

## Ops Notes

### Zero Downtime Deployments

Zero downtime deployments can be achieved using:

- **Blue/Green deployments**
- **Rolling updates**
- **Auto Scaling Instance Refresh**

---

## Secrets Management

Secrets should **not be stored in Terraform variables**.

### Recommended Solutions

- **AWS Secrets Manager**
- **AWS Systems Manager Parameter Store**

Applications should **retrieve secrets securely at runtime**.

---

## Production Monitoring

In production environments, monitoring would include:

### Infrastructure

- CPU utilization
- Memory usage
- Disk usage

### Application

- HTTP error rate
- Latency
- Request throughput

### Security

- Abnormal traffic patterns
- WAF logs
- Access anomalies

Alerts can be integrated with **SNS** or **PagerDuty**.

---

## Possible Improvements

Future enhancements could include:

- **AWS WAF integration**
- **VPC Endpoints for S3 and SSM**
- **ALB access logs to S3**
- **Terraform CI pipeline (fmt / validate / plan)**
- **HTTPS redirect with HSTS**

Created with ❤️ by Tanishka
