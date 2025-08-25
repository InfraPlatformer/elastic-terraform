# =============================================================================
# OUTPUTS FOR NETWORKING MODULE
# =============================================================================

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnets" {
  description = "List of public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnets" {
  description = "List of private subnet IDs"
  value       = aws_subnet.private[*].id
}

output "public_subnet_cidrs" {
  description = "List of public subnet CIDR blocks"
  value       = aws_subnet.public[*].cidr_block
}

output "private_subnet_cidrs" {
  description = "List of private subnet CIDR blocks"
  value       = aws_subnet.private[*].cidr_block
}

output "nat_gateway_ips" {
  description = "List of NAT Gateway public IPs"
  value       = aws_eip.nat[*].public_ip
}

output "eks_cluster_security_group_id" {
  description = "Security group ID for EKS cluster"
  value       = aws_security_group.eks_cluster_enhanced.id
}

output "eks_nodes_security_group_id" {
  description = "Security group ID for EKS nodes"
  value       = aws_security_group.eks_nodes_enhanced.id
}

output "elasticsearch_security_group_id" {
  description = "Security group ID for Elasticsearch"
  value       = aws_security_group.elasticsearch_enhanced.id
}

output "kibana_security_group_id" {
  description = "Security group ID for Kibana"
  value       = aws_security_group.kibana_enhanced.id
}

output "vpc_endpoints" {
  description = "VPC endpoints created"
  value = {
    s3     = var.enable_vpc_endpoints ? aws_vpc_endpoint.s3[0].id : null
    ecr_dkr = var.enable_vpc_endpoints ? aws_vpc_endpoint.ecr_dkr[0].id : null
    ecr_api = var.enable_vpc_endpoints ? aws_vpc_endpoint.ecr_api[0].id : null
  }
}

