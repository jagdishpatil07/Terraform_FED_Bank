locals {
  name_prefix = var.name_prefix
}

data "aws_availability_zones" "az" {}

##########################
# VPCs + Private Subnets #
##########################

resource "aws_vpc" "uat" {
  cidr_block = var.uat_vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = { Name = "${local.name_prefix}-uat-vpc" }
}

resource "aws_subnet" "uat_app" {
  vpc_id                  = aws_vpc.uat.id
  cidr_block              = cidrsubnet(aws_vpc.uat.cidr_block, 8, 1)
  availability_zone       = element(data.aws_availability_zones.az.names, 0)
  map_public_ip_on_launch = false
  tags = { Name = "${local.name_prefix}-uat-app-subnet" }
}

resource "aws_subnet" "uat_db" {
  vpc_id                  = aws_vpc.uat.id
  cidr_block              = cidrsubnet(aws_vpc.uat.cidr_block, 8, 2)
  availability_zone       = element(data.aws_availability_zones.az.names, 1)
  map_public_ip_on_launch = false
  tags = { Name = "${local.name_prefix}-uat-db-subnet" }
}

resource "aws_vpc" "prod" {
  cidr_block = var.prod_vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = { Name = "${local.name_prefix}-prod-vpc" }
}

resource "aws_subnet" "prod_app" {
  vpc_id                  = aws_vpc.prod.id
  cidr_block              = cidrsubnet(aws_vpc.prod.cidr_block, 8, 1)
  availability_zone       = element(data.aws_availability_zones.az.names, 0)
  map_public_ip_on_launch = false
  tags = { Name = "${local.name_prefix}-prod-app-subnet" }
}

resource "aws_subnet" "prod_db" {
  vpc_id                  = aws_vpc.prod.id
  cidr_block              = cidrsubnet(aws_vpc.prod.cidr_block, 8, 2)
  availability_zone       = element(data.aws_availability_zones.az.names, 1)
  map_public_ip_on_launch = false
  tags = { Name = "${local.name_prefix}-prod-db-subnet" }
}

###########################
# Private Route Tables
###########################
resource "aws_route_table" "uat_priv_rt" {
  vpc_id = aws_vpc.uat.id
  tags = { Name = "${local.name_prefix}-uat-priv-rt" }
}

resource "aws_route_table_association" "uat_app_assoc" {
  subnet_id      = aws_subnet.uat_app.id
  route_table_id = aws_route_table.uat_priv_rt.id
}

resource "aws_route_table_association" "uat_db_assoc" {
  subnet_id      = aws_subnet.uat_db.id
  route_table_id = aws_route_table.uat_priv_rt.id
}

resource "aws_route_table" "prod_priv_rt" {
  vpc_id = aws_vpc.prod.id
  tags = { Name = "${local.name_prefix}-prod-priv-rt" }
}

resource "aws_route_table_association" "prod_app_assoc" {
  subnet_id      = aws_subnet.prod_app.id
  route_table_id = aws_route_table.prod_priv_rt.id
}

resource "aws_route_table_association" "prod_db_assoc" {
  subnet_id      = aws_subnet.prod_db.id
  route_table_id = aws_route_table.prod_priv_rt.id
}

#########################
# Transit Gateway (TGW) #
#########################
resource "aws_ec2_transit_gateway" "tgw" {
  description = "${local.name_prefix}-tgw"
  tags = { Name = "${local.name_prefix}-tgw" }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "uat_attach" {
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  vpc_id             = aws_vpc.uat.id
  subnet_ids         = [aws_subnet.uat_app.id, aws_subnet.uat_db.id]
  tags = { Name = "${local.name_prefix}-uat-tgw-attach" }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "prod_attach" {
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  vpc_id             = aws_vpc.prod.id
  subnet_ids         = [aws_subnet.prod_app.id, aws_subnet.prod_db.id]
  tags = { Name = "${local.name_prefix}-prod-tgw-attach" }
}

# Add route in VPC route tables to send client CIDR traffic to TGW
resource "aws_route" "uat_to_tgw_client" {
  route_table_id         = aws_route_table.uat_priv_rt.id
  destination_cidr_block = var.client_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.tgw.id
}

resource "aws_route" "prod_to_tgw_client" {
  route_table_id         = aws_route_table.prod_priv_rt.id
  destination_cidr_block = var.client_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.tgw.id
}

####################################
# Customer Gateway + VPN Connection
####################################
resource "aws_customer_gateway" "client_cgw" {
  bgp_asn    = 65000
  ip_address = var.customer_gateway_public_ip
  type       = "ipsec.1"
  tags = { Name = "${local.name_prefix}-customer-gw" }
}

resource "aws_vpn_connection" "tgw_vpn" {
  transit_gateway_id  = aws_ec2_transit_gateway.tgw.id
  customer_gateway_id = aws_customer_gateway.client_cgw.id
  type                = "ipsec.1"
  static_routes_only  = true
  tags = { Name = "${local.name_prefix}-tgw-vpn" }
}

# advertise VPC CIDRs to the customer via the VPN connection routes
resource "aws_vpn_connection_route" "uat_route" {
  vpn_connection_id       = aws_vpn_connection.tgw_vpn.id
  destination_cidr_block  = aws_vpc.uat.cidr_block
}
resource "aws_vpn_connection_route" "prod_route" {
  vpn_connection_id       = aws_vpn_connection.tgw_vpn.id
  destination_cidr_block  = aws_vpc.prod.cidr_block
}

# TGW route table and associations
resource "aws_ec2_transit_gateway_route_table" "tgw_rt" {
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  tags = { Name = "${local.name_prefix}-tgw-rt" }
}

resource "aws_ec2_transit_gateway_route_table_association" "uat_assoc" {
  transit_gateway_attachment_id = aws_ec2_transit_gateway_vpc_attachment.uat_attach.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgw_rt.id
}
resource "aws_ec2_transit_gateway_route_table_association" "prod_assoc" {
  transit_gateway_attachment_id = aws_ec2_transit_gateway_vpc_attachment.prod_attach.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgw_rt.id
}

# create TGW route to client CIDR via the VPN
resource "aws_ec2_transit_gateway_route" "to_client" {
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgw_rt.id
  destination_cidr_block         = var.client_cidr
  transit_gateway_attachment_id  = aws_vpn_connection.tgw_vpn.transit_gateway_attachment_id
}

##################
# VPC Endpoints for S3 and SSM (no internet required)
##################
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.uat.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.uat_priv_rt.id, aws_route_table.prod_priv_rt.id]
  tags = { Name = "${local.name_prefix}-vpce-s3" }
}

# SSM interface endpoints in each VPC
resource "aws_vpc_endpoint" "ssm_ua" {
  vpc_id            = aws_vpc.uat.id
  service_name      = "com.amazonaws.${var.aws_region}.ssm"
  vpc_endpoint_type = "Interface"
  subnet_ids        = [aws_subnet.uat_app.id, aws_subnet.uat_db.id]
  security_group_ids= [aws_security_group.uat_app_sg.id]
  tags = { Name = "${local.name_prefix}-vpce-ssm-uat" }
}

resource "aws_vpc_endpoint" "ssm_prod" {
  vpc_id            = aws_vpc.prod.id
  service_name      = "com.amazonaws.${var.aws_region}.ssm"
  vpc_endpoint_type = "Interface"
  subnet_ids        = [aws_subnet.prod_app.id, aws_subnet.prod_db.id]
  security_group_ids= [aws_security_group.prod_app_sg.id]
  tags = { Name = "${local.name_prefix}-vpce-ssm-prod" }
}

resource "aws_vpc_endpoint" "ec2msg_ua" {
  vpc_id            = aws_vpc.uat.id
  service_name      = "com.amazonaws.${var.aws_region}.ec2messages"
  vpc_endpoint_type = "Interface"
  subnet_ids        = [aws_subnet.uat_app.id, aws_subnet.uat_db.id]
  security_group_ids= [aws_security_group.uat_app_sg.id]
  tags = { Name = "${local.name_prefix}-vpce-ec2msg-uat" }
}

resource "aws_vpc_endpoint" "ec2msg_prod" {
  vpc_id            = aws_vpc.prod.id
  service_name      = "com.amazonaws.${var.aws_region}.ec2messages"
  vpc_endpoint_type = "Interface"
  subnet_ids        = [aws_subnet.prod_app.id, aws_subnet.prod_db.id]
  security_group_ids= [aws_security_group.prod_app_sg.id]
  tags = { Name = "${local.name_prefix}-vpce-ec2msg-prod" }
}

resource "aws_vpc_endpoint" "ssmmessages_ua" {
  vpc_id            = aws_vpc.uat.id
  service_name      = "com.amazonaws.${var.aws_region}.ssmmessages"
  vpc_endpoint_type = "Interface"
  subnet_ids        = [aws_subnet.uat_app.id, aws_subnet.uat_db.id]
  security_group_ids= [aws_security_group.uat_app_sg.id]
  tags = { Name = "${local.name_prefix}-vpce-ssmmessages-uat" }
}

resource "aws_vpc_endpoint" "ssmmessages_prod" {
  vpc_id            = aws_vpc.prod.id
  service_name      = "com.amazonaws.${var.aws_region}.ssmmessages"
  vpc_endpoint_type = "Interface"
  subnet_ids        = [aws_subnet.prod_app.id, aws_subnet.prod_db.id]
  security_group_ids= [aws_security_group.prod_app_sg.id]
  tags = { Name = "${local.name_prefix}-vpce-ssmmessages-prod" }
}

##################
# IAM for EC2 SSM
##################
resource "aws_iam_role" "ec2_ssm_role" {
  name = "${local.name_prefix}-ec2-ssm-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Principal = { Service = "ec2.amazonaws.com" }
      Effect = "Allow"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_attach" {
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_ssm_profile" {
  name = "${local.name_prefix}-ec2-ssm-profile"
  role = aws_iam_role.ec2_ssm_role.name
}

#################
# SecurityGroups
#################
# UAT app SG - allow SSH (22) from client CIDR and HTTP/HTTPS from client CIDR
resource "aws_security_group" "uat_app_sg" {
  name        = "${local.name_prefix}-uat-app-sg"
  vpc_id      = aws_vpc.uat.id
  description = "UAT App SG - SSH/HTTP/HTTPS from client network"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.client_cidr]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.client_cidr]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.client_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${local.name_prefix}-uat-app-sg" }
}

# UAT db SG - MSSQL from app SG, RDP from client CIDR
resource "aws_security_group" "uat_db_sg" {
  name   = "${local.name_prefix}-uat-db-sg"
  vpc_id = aws_vpc.uat.id

  ingress {
    from_port       = 1433
    to_port         = 1433
    protocol        = "tcp"
    security_groups = [aws_security_group.uat_app_sg.id]
    description     = "MSSQL from app servers"
  }

  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = [var.client_cidr]
    description = "RDP from client network"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "${local.name_prefix}-uat-db-sg" }
}

# Prod app SG
resource "aws_security_group" "prod_app_sg" {
  name   = "${local.name_prefix}-prod-app-sg"
  vpc_id = aws_vpc.prod.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.client_cidr]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.client_cidr]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.client_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "${local.name_prefix}-prod-app-sg" }
}

# Prod db SG
resource "aws_security_group" "prod_db_sg" {
  name   = "${local.name_prefix}-prod-db-sg"
  vpc_id = aws_vpc.prod.id

  ingress {
    from_port       = 1433
    to_port         = 1433
    protocol        = "tcp"
    security_groups = [aws_security_group.prod_app_sg.id]
    description     = "MSSQL from prod app"
  }

  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = [var.client_cidr]
    description = "RDP from client network"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "${local.name_prefix}-prod-db-sg" }
}

#################
# EC2 Instances
#################
# UAT App (Ubuntu)
resource "aws_instance" "uat_app" {
  ami                         = var.ubuntu_ami
  instance_type               = var.uat_app_instance_type
  subnet_id                   = aws_subnet.uat_app.id
  vpc_security_group_ids      = [aws_security_group.uat_app_sg.id]
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.ec2_ssm_profile.name
  key_name                    = var.fedbank_ssh_key_name != "" ? var.fedbank_ssh_key_name : null

  root_block_device {
    volume_size = var.uat_app_root_disk_gb
    volume_type = "gp3"
    delete_on_termination = true
  }

  tags = { Name = "${local.name_prefix}-uat-app" }
}

# UAT DB (Windows)
resource "aws_instance" "uat_db" {
  ami                         = var.windows_ami
  instance_type               = var.uat_db_instance_type
  subnet_id                   = aws_subnet.uat_db.id
  vpc_security_group_ids      = [aws_security_group.uat_db_sg.id]
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.ec2_ssm_profile.name
  key_name                    = var.fedbank_ssh_key_name != "" ? var.fedbank_ssh_key_name : null

  root_block_device {
    volume_size = var.uat_db_root_disk_gb
    volume_type = "gp3"
    delete_on_termination = true
  }

  tags = { Name = "${local.name_prefix}-uat-db" }
}

# Prod App (Linux)
resource "aws_instance" "prod_app" {
  ami                         = var.ubuntu_ami
  instance_type               = var.prod_app_instance_type
  subnet_id                   = aws_subnet.prod_app.id
  vpc_security_group_ids      = [aws_security_group.prod_app_sg.id]
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.ec2_ssm_profile.name
  key_name                    = var.fedbank_ssh_key_name != "" ? var.fedbank_ssh_key_name : null

  root_block_device {
    volume_size = var.prod_app_root_disk_gb
    volume_type = "gp3"
    delete_on_termination = true
  }

  tags = { Name = "${local.name_prefix}-prod-app" }
}

# Prod DB (Windows)
resource "aws_instance" "prod_db" {
  ami                         = var.windows_ami
  instance_type               = var.prod_db_instance_type
  subnet_id                   = aws_subnet.prod_db.id
  vpc_security_group_ids      = [aws_security_group.prod_db_sg.id]
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.ec2_ssm_profile.name
  key_name                    = var.fedbank_ssh_key_name != "" ? var.fedbank_ssh_key_name : null

  root_block_device {
    volume_size = var.prod_db_root_disk_gb
    volume_type = "gp3"
    delete_on_termination = true
  }

  tags = { Name = "${local.name_prefix}-prod-db" }
}
