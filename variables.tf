variable "aws_region" {
  description = "AWS region to deploy into (e.g. us-east-1)"
  type        = string
  default     = ""
}

variable "name_prefix" {
  description = "Name prefix for resources"
  type        = string
  default     = "FEDBank"
}

# AMIs (must be valid for the chosen region and architecture)
variable "ubuntu_ami" {
  description = "Ubuntu AMI id for app servers (arm64 for t4g/r7i if required)"
  type        = string
  default     = ""
}

variable "windows_ami" {
  description = "Windows Server AMI id for MSSQL DB instances"
  type        = string
  default     = ""
}

# Instance types (defaults set to requested types)
variable "uat_app_instance_type" {
  type    = string
  default = "t4g.xlarge"
}

variable "uat_db_instance_type" {
  type    = string
  default = "t3g.xlarge"
}

variable "prod_app_instance_type" {
  type    = string
  default = "r7i.xlarge"
}

variable "prod_db_instance_type" {
  type    = string
  default = "t3.xlarge"
}

# Root disk sizes (GB)
variable "uat_app_root_disk_gb" {
  type    = number
  default = 128
}

variable "uat_db_root_disk_gb" {
  type    = number
  default = 250
}

variable "prod_app_root_disk_gb" {
  type    = number
  default = 250
}

variable "prod_db_root_disk_gb" {
  type    = number
  default = 500
}

# VPC CIDRs (leave blank to fill later)
variable "uat_vpc_cidr" {
  type    = string
  default = ""
}

variable "prod_vpc_cidr" {
  type    = string
  default = ""
}

# Client / Customer info (leave blank to fill later)
variable "client_cidr" {
  description = "Client internal CIDR that will access AWS via VPN (e.g. 192.168.100.0/24)"
  type        = string
  default     = ""
}

variable "customer_gateway_public_ip" {
  description = "Public IP of customer's firewall (for aws_customer_gateway)"
  type        = string
  default     = ""
}

# SSH key - used only if you enable SSH; SSM is primary access
variable "fedbank_ssh_key_name" {
  description = "Optional SSH key name (create in EC2 console) if you need SSH access"
  type        = string
  default     = ""
}
