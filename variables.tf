variable "aws_region" {
  description = "AWS region to deploy resources (example: us-east-1)"
  type        = string
  default     = "us-east-1"
}

variable "name_prefix" {
  description = "Name prefix used for all resource names"
  type        = string
  default     = "FEDBank"
}

variable "ubuntu_ami" {
  description = "Ubuntu AMI ID for application servers (optional - will use latest if empty)"
  type        = string
  default     = ""
}

variable "windows_ami" {
  description = "Windows Server AMI ID for DB servers (optional - will use latest if empty)"
  type        = string
  default     = ""
}

variable "uat_app_instance_type" {
  description = "Instance type for UAT application server"
  type        = string
  default     = "t4g.xlarge"
}

variable "uat_db_instance_type" {
  default = "t3.xlarge"
}

variable "prod_app_instance_type" {
  description = "Instance type for Production application server"
  type        = string
  default     = "r7i.xlarge"
}

variable "prod_db_instance_type" {
  description = "Instance type for Production DB server"
  type        = string
  default     = "t3.xlarge"
}

variable "uat_app_root_disk_gb" {
  description = "Root disk size (GB) for UAT app server"
  type        = number
  default     = 128
}

variable "uat_db_root_disk_gb" {
  description = "Root disk size (GB) for UAT DB server"
  type        = number
  default     = 250
}

variable "prod_app_root_disk_gb" {
  description = "Root disk size (GB) for Production app server"
  type        = number
  default     = 250
}

variable "prod_db_root_disk_gb" {
  description = "Root disk size (GB) for Production DB server"
  type        = number
  default     = 500
}

variable "uat_vpc_cidr" {
  description = "CIDR block for UAT VPC (example: 10.10.0.0/16)"
  type        = string
  default     = ""
}

variable "prod_vpc_cidr" {
  description = "CIDR block for Production VPC (example: 10.20.0.0/16)"
  type        = string
  default     = ""
}

variable "client_cidr" {
  description = "Client on-prem CIDR (example: 192.168.100.0/24)"
  type        = string
  default     = ""
}

variable "customer_gateway_public_ip" {
  description = "Customer firewall/router public IP for VPN"
  type        = string
  default     = ""
}

variable "fedbank_ssh_key_name" {
  description = "SSH key name for EC2 instances if SSH is required (optional)"
  type        = string
  default     = ""
}

