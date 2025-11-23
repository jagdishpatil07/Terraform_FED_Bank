aws_region = "us-east-1"
name_prefix = "FEDBank"

# If you want to override AMIs, put the AMI ids here; otherwise leave blank to use latest data lookup
ubuntu_ami  = ""      # optional; leave blank to auto-select latest ARM64 Ubuntu 22.04
windows_ami = ""      # optional; leave blank to auto-select latest Windows Server 2019

uat_vpc_cidr  = "10.10.0.0/16"
prod_vpc_cidr = "10.20.0.0/16"

client_cidr = "192.168.100.0/24"
customer_gateway_public_ip = "4.4.4.4"

fedbank_ssh_key_name = ""
