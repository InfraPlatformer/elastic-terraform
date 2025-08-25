# =============================================================================
# NETWORKING INFRASTRUCTURE FOR ADVANCED ELASTIC TERRAFORM
# =============================================================================
# This module creates the networking infrastructure for the Elastic stack
# - VPC with public and private subnets
# - NAT Gateways for private subnet internet access
# - VPC Endpoints for AWS services
# - Security Groups (defined in security-groups.tf)
# =============================================================================

# =============================================================================
# VPC
# =============================================================================

# Main VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = merge(var.tags, {
    Name = "${var.environment}-elastic-vpc"
    Type = "VPC"
  })
}

# =============================================================================
# INTERNET GATEWAY
# =============================================================================

# Internet Gateway for public subnets
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  
  tags = merge(var.tags, {
    Name = "${var.environment}-elastic-igw"
    Type = "Internet Gateway"
  })
}

# =============================================================================
# SUBNETS
# =============================================================================

# Public Subnets
resource "aws_subnet" "public" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone = var.availability_zones[count.index]
  
  map_public_ip_on_launch = true
  
  tags = merge(var.tags, {
    Name = "${var.environment}-elastic-public-${var.availability_zones[count.index]}"
    Type = "Public Subnet"
    Tier = "Public"
  })
}

# Private Subnets
resource "aws_subnet" "private" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + length(var.availability_zones))
  availability_zone = var.availability_zones[count.index]
  
  tags = merge(var.tags, {
    Name = "${var.environment}-elastic-private-${var.availability_zones[count.index]}"
    Type = "Private Subnet"
    Tier = "Private"
  })
}

# =============================================================================
# ROUTE TABLES
# =============================================================================

# Route Table for Public Subnets
resource "aws_route_table" "public" {
  count  = length(var.availability_zones)
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  
  tags = merge(var.tags, {
    Name = "${var.environment}-elastic-public-rt-${var.availability_zones[count.index]}"
    Type = "Public Route Table"
  })
}

# Route Table for Private Subnets
resource "aws_route_table" "private" {
  count  = length(var.availability_zones)
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }
  
  tags = merge(var.tags, {
    Name = "${var.environment}-elastic-private-rt-${var.availability_zones[count.index]}"
    Type = "Private Route Table"
  })
}

# =============================================================================
# ROUTE TABLE ASSOCIATIONS
# =============================================================================

# Associate Public Subnets with Public Route Table
resource "aws_route_table_association" "public" {
  count          = length(var.availability_zones)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[count.index].id
}

# Associate Private Subnets with Private Route Table
resource "aws_route_table_association" "private" {
  count          = length(var.availability_zones)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# =============================================================================
# NAT GATEWAYS
# =============================================================================

# Elastic IPs for NAT Gateways
resource "aws_eip" "nat" {
  count  = length(var.availability_zones)
  domain = "vpc"
  
  tags = merge(var.tags, {
    Name = "${var.environment}-elastic-nat-eip-${var.availability_zones[count.index]}"
    Type = "NAT Gateway EIP"
  })
}

# NAT Gateways
resource "aws_nat_gateway" "main" {
  count         = length(var.availability_zones)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  
  tags = merge(var.tags, {
    Name = "${var.environment}-elastic-nat-${var.availability_zones[count.index]}"
    Type = "NAT Gateway"
  })
  
  depends_on = [aws_internet_gateway.main]
}

# =============================================================================
# VPC ENDPOINTS (OPTIONAL)
# =============================================================================

# VPC Endpoint for S3 (for EKS image pulling)
resource "aws_vpc_endpoint" "s3" {
  count             = var.enable_vpc_endpoints ? 1 : 0
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${data.aws_region.current.id}.s3"
  vpc_endpoint_type = "Gateway"
  
  route_table_ids = concat(
    [aws_route_table.private[0].id],
    slice(aws_route_table.private[*].id, 1, length(var.availability_zones))
  )
  
  tags = merge(var.tags, {
    Name = "${var.environment}-elastic-s3-endpoint"
    Type = "S3 VPC Endpoint"
  })
}

# VPC Endpoint for ECR (for container images)
resource "aws_vpc_endpoint" "ecr_dkr" {
  count             = var.enable_vpc_endpoints ? 1 : 0
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${data.aws_region.current.id}.ecr.dkr"
  vpc_endpoint_type = "Interface"
  subnet_ids        = aws_subnet.private[*].id
  
  private_dns_enabled = true
  security_group_ids  = [aws_security_group.eks_cluster_enhanced.id]
  
  tags = merge(var.tags, {
    Name = "${var.environment}-elastic-ecr-dkr-endpoint"
    Type = "ECR DKR VPC Endpoint"
  })
}

# VPC Endpoint for ECR API
resource "aws_vpc_endpoint" "ecr_api" {
  count             = var.enable_vpc_endpoints ? 1 : 0
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${data.aws_region.current.id}.ecr.api"
  vpc_endpoint_type = "Interface"
  subnet_ids        = aws_subnet.private[*].id
  
  private_dns_enabled = true
  security_group_ids  = [aws_security_group.eks_cluster_enhanced.id]
  
  tags = merge(var.tags, {
    Name = "${var.environment}-elastic-ecr-api-endpoint"
    Type = "ECR API VPC Endpoint"
  })
}

# =============================================================================
# DATA SOURCES
# =============================================================================

data "aws_region" "current" {}

