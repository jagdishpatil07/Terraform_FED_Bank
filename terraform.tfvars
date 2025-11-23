aws_region = "us-east-1"
name_prefix = "FEDBank"

# AMIs for us-east-1 (Test values)
# Ubuntu 22.04 ARM (for t4g.xlarge / r7i.xlarge instances)
ubuntu_ami  = "ami-02a7f3fd431e4f19e"

# Windows Server 2019 Base (for MSSQL installation)
windows_ami = "ami-0e4f1a1a4a485b297"

# VPC CIDRs - example non-overlapping ranges
uat_vpc_cidr  = "10.10.0.0/16"
prod_vpc_cidr = "10.20.0.0/16"

# Client CIDR (dummy for testing)
client_cidr = "192.168.100.0/24"

# Dummy customer gateway public IP (for testing only)
customer_gateway_public_ip = "4.4.4.4"

# SSH key (optional)
fedbank_ssh_key_name = ""
