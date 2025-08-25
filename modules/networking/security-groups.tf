# =============================================================================
# ENHANCED SECURITY GROUP CONFIGURATIONS FOR PRODUCTION
# =============================================================================

# Enhanced EKS Cluster Security Group
resource "aws_security_group" "eks_cluster_enhanced" {
  name_prefix = "${var.environment}-elastic-eks-cluster-enhanced-"
  description = "Enhanced EKS Cluster Security Group with production security rules"
  vpc_id      = aws_vpc.main.id

  # HTTPS from VPC only (EKS control plane communication)
  ingress {
    description      = "Allow HTTPS from VPC only for EKS control plane communication"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = [var.vpc_cidr]
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    security_groups  = []
    self             = false
  }



  # Allow cluster to communicate with nodes
  ingress {
    description      = "Allow cluster to communicate with nodes"
    from_port        = 10250
    to_port          = 10250
    protocol         = "tcp"
    cidr_blocks      = [var.vpc_cidr]
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    security_groups  = []
    self             = false
  }

  # Egress - allow necessary outbound traffic
  egress {
    description      = "Allow all outbound traffic (required for EKS functionality)"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    security_groups  = []
    self             = false
  }

  tags = merge(var.tags, {
    Name = "${var.environment}-elastic-eks-cluster-enhanced-sg"
    Type = "Enhanced EKS Cluster Security Group"
    SecurityLevel = "High"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Enhanced EKS Nodes Security Group
resource "aws_security_group" "eks_nodes_enhanced" {
  name_prefix = "${var.environment}-elastic-eks-nodes-enhanced-"
  description = "Enhanced EKS Worker Nodes Security Group with production security rules"
  vpc_id      = aws_vpc.main.id

  # Allow EKS cluster to communicate with nodes
  ingress {
    description      = "Allow EKS cluster to communicate with nodes"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = [var.vpc_cidr]
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    security_groups  = []
    self             = false
  }

  # Allow SSH access from VPC only
  ingress {
    description      = "Allow SSH access from VPC only"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = [var.vpc_cidr]
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    security_groups  = []
    self             = false
  }

  # Allow kubelet communication from VPC
  ingress {
    description      = "Allow kubelet communication from VPC"
    from_port        = 10250
    to_port          = 10250
    protocol         = "tcp"
    cidr_blocks      = [var.vpc_cidr]
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    security_groups  = []
    self             = false
  }

  # NodePort services - restrict to VPC only
  ingress {
    description      = "Allow NodePort services from VPC only"
    from_port        = 30000
    to_port          = 32767
    protocol         = "tcp"
    cidr_blocks      = [var.vpc_cidr]
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    security_groups  = []
    self             = false
  }

  # Read-only kubelet port
  ingress {
    description      = "Allow read-only kubelet access from VPC"
    from_port        = 10255
    to_port          = 10255
    protocol         = "tcp"
    cidr_blocks      = [var.vpc_cidr]
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    security_groups  = []
    self             = false
  }

  # EKS control plane to worker node communication (ephemeral ports)
  ingress {
    description      = "Allow EKS control plane to worker node communication (ephemeral ports)"
    from_port        = 1024
    to_port          = 1031
    protocol         = "tcp"
    cidr_blocks      = [var.vpc_cidr]
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    security_groups  = []
    self             = false
  }

  # Egress - allow necessary outbound traffic
  egress {
    description      = "Allow all outbound traffic (required for EKS node functionality)"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    security_groups  = []
    self             = false
  }

  tags = merge(var.tags, {
    Name = "${var.environment}-elastic-eks-nodes-enhanced-sg"
    Type = "Enhanced EKS Nodes Security Group"
    SecurityLevel = "High"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Enhanced Elasticsearch Security Group
resource "aws_security_group" "elasticsearch_enhanced" {
  name_prefix = "${var.environment}-elastic-elasticsearch-enhanced-"
  description = "Enhanced Elasticsearch Security Group with production security rules"
  vpc_id      = aws_vpc.main.id

  # HTTP access from EKS cluster only
  ingress {
    description      = "Allow HTTP access to Elasticsearch from EKS cluster only"
    from_port        = 9200
    to_port          = 9200
    protocol         = "tcp"
    security_groups  = [aws_security_group.eks_cluster_enhanced.id]
    cidr_blocks      = []
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    self             = false
  }

  # Transport access from EKS cluster only
  ingress {
    description      = "Allow transport access to Elasticsearch from EKS cluster only"
    from_port        = 9300
    to_port          = 9300
    protocol         = "tcp"
    security_groups  = [aws_security_group.eks_cluster_enhanced.id]
    cidr_blocks      = []
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    self             = false
  }

  # Egress - allow necessary outbound traffic
  egress {
    description      = "Allow all outbound traffic (required for Elasticsearch functionality)"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    security_groups  = []
    self             = false
  }

  tags = merge(var.tags, {
    Name = "${var.environment}-elastic-elasticsearch-enhanced-sg"
    Type = "Enhanced Elasticsearch Security Group"
    SecurityLevel = "High"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Enhanced Kibana Security Group
resource "aws_security_group" "kibana_enhanced" {
  name_prefix = "${var.environment}-elastic-kibana-enhanced-"
  description = "Enhanced Kibana Security Group with production security rules"
  vpc_id      = aws_vpc.main.id

  # HTTP access from EKS cluster only
  ingress {
    description      = "Allow HTTP access to Kibana from EKS cluster only"
    from_port        = 5601
    to_port          = 5601
    protocol         = "tcp"
    security_groups  = [aws_security_group.eks_cluster_enhanced.id]
    cidr_blocks      = []
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    self             = false
  }

  # Egress - allow necessary outbound traffic
  egress {
    description      = "Allow all outbound traffic (required for Kibana functionality)"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    security_groups  = []
    self             = false
  }

  tags = merge(var.tags, {
    Name = "${var.environment}-elastic-kibana-enhanced-sg"
    Type = "Enhanced Kibana Security Group"
    SecurityLevel = "High"
  })

  lifecycle {
    create_before_destroy = true
  }
}
