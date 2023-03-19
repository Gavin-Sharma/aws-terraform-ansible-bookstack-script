# aws-terraform-ansible-bookstack-script
###### [Documentation](https://docs.google.com/document/d/10svFtEWZuTkrUooxrhUX1qUXqv7nC3ghG345ZXahjl0/edit?usp=sharing "Documentation")
------------

## Infrastructure using Terraform
This project aims to create infrastructure on AWS using Terraform. The infrastructure consists of a VPC with three subnets (one public and two private), an Internet Gateway, a Route Table, two Security Groups (one for EC2 instances and another for RDS), an EC2 instance, and an RDS database cluster.

### Prerequisites
Before running the Terraform configuration, you must have the following:

- An AWS account
- AWS credentials with sufficient permissions to create the infrastructure
- Terraform CLI installed on your machine

------------

## Application using Ansible
This project also includes setting up part of an application using Ansible. The tasks include installing and configuring Nginx or Apache, creating a simple "Hello World" HTML document, configuring the database, and copying the server configuration files and HTML document from the local development environment to the server.

### Prerequisites
Before running the Ansible playbook, you must have the following:

- Ansible installed on your machine
- A server instance with SSH access
