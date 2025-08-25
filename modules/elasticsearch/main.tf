# =============================================================================
# ELASTICSEARCH MODULE FOR ADVANCED ELASTIC TERRAFORM
# =============================================================================
# This module creates an EKS cluster and deploys Elasticsearch using Helm
# - EKS cluster with managed node groups
# - Elasticsearch deployment with Helm
# - Persistent storage and security configuration
# =============================================================================

# =============================================================================
# EKS CLUSTER
# =============================================================================

# EKS Cluster
resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster.arn
  version  = var.cluster_version
  
  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_private_access = true
    endpoint_public_access  = var.enable_public_access
    security_group_ids      = [var.cluster_security_group_id, var.nodes_security_group_id]
    
    # Only set public_access_cidrs if public access is enabled
    public_access_cidrs = var.enable_public_access ? var.allowed_cidr_blocks : null
  }
  
  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  
  # Add configurations to match imported cluster and prevent replacement
  bootstrap_self_managed_addons = false
  
  access_config {
    authentication_mode                         = "CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }
  
  kubernetes_network_config {
    ip_family         = "ipv4"
    service_ipv4_cidr = "172.20.0.0/16"
    
    elastic_load_balancing {
      enabled = false
    }
  }
  
  upgrade_policy {
    support_type = "EXTENDED"
  }
  
  # Encryption disabled for now due to KMS permissions
  # dynamic "encryption_config" {
  #   for_each = var.enable_encryption_at_rest ? [1] : []
  #   content {
  #     resources = ["secrets"]
  #     provider {
  #       key_arn = aws_kms_key.eks[0].arn
  #     }
  #   }
  # }
  
  tags = merge(var.tags, {
    Name = var.cluster_name
    Type = "EKS Cluster"
  })
  
  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_iam_role_policy_attachment.eks_vpc_resource_controller,
  ]
  
  lifecycle {
    create_before_destroy = true
    ignore_changes        = [tags["CreatedAt"]]
  }
}

# EKS Cluster IAM Role
resource "aws_iam_role" "eks_cluster" {
  name = "${var.cluster_name}-cluster-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })
  
  tags = var.tags
}

# EKS Cluster Policy
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}

# EKS VPC Resource Controller Policy
resource "aws_iam_role_policy_attachment" "eks_vpc_resource_controller" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks_cluster.name
}

# =============================================================================
# EKS NODE GROUPS
# =============================================================================

# EKS Node Group IAM Role
resource "aws_iam_role" "eks_nodes" {
  name = "${var.cluster_name}-nodes-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
  
  tags = var.tags
}

# EKS Node Group Policies
resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "ec2_container_registry_read_only" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_nodes.name
}

# EBS CSI Driver Policy
resource "aws_iam_role_policy_attachment" "ebs_csi_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.eks_nodes.name
}

# EKS Describe Cluster Policy (Required for worker nodes to join cluster)
resource "aws_iam_role_policy" "eks_describe_cluster" {
  name = "eks-describe-cluster"
  role = aws_iam_role.eks_nodes.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters"
        ]
        Effect = "Allow"
        Resource = aws_eks_cluster.main.arn
      }
    ]
  })
}

# Additional EKS worker node permissions for better functionality
resource "aws_iam_role_policy" "eks_worker_additional" {
  name = "eks-worker-additional-permissions"
  role = aws_iam_role.eks_nodes.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeRegions",
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# =============================================================================
# NODE GROUPS
# =============================================================================

# Create node groups for each configuration
resource "aws_eks_node_group" "main" {
  for_each = var.node_groups
  
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.cluster_name}-${each.key}"
  node_role_arn   = aws_iam_role.eks_nodes.arn
  subnet_ids      = var.subnet_ids
  
  # Attach proper security groups for node communication
  # Security groups are configured at the cluster level
  # The node group will inherit the cluster's security group configuration
  
  instance_types = each.value.instance_types
  capacity_type  = each.value.capacity_type
  
  scaling_config {
    desired_size = each.value.desired_size
    max_size     = each.value.max_size
    min_size     = each.value.min_size
  }
  
  disk_size = each.value.disk_size
  
  labels = merge(each.value.labels, {
    "node.kubernetes.io/role" = each.key
  })
  
  dynamic "taint" {
    for_each = each.value.taints
    content {
      key    = taint.value.key
      value  = taint.value.value
      effect = taint.value.effect
    }
  }
  
  tags = merge(var.tags, {
    Name = "${var.cluster_name}-${each.key}-ng"
    Type = "EKS Node Group"
  })
  
  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.ec2_container_registry_read_only,
    aws_iam_role_policy.eks_describe_cluster,
    aws_iam_role_policy.eks_worker_additional,
  ]
  
  lifecycle {
    create_before_destroy = true
    ignore_changes        = [tags["CreatedAt"]]
  }
}

# =============================================================================
# KMS ENCRYPTION (OPTIONAL)
# =============================================================================

# KMS Key for EKS encryption - Disabled due to permissions
resource "aws_kms_key" "eks" {
  count = 0  # Disabled - var.enable_encryption_at_rest ? 1 : 0
  
  description             = "KMS key for EKS cluster encryption"
  deletion_window_in_days = 7
  enable_key_rotation    = true
  
  tags = merge(var.tags, {
    Name = "${var.cluster_name}-encryption-key"
    Type = "KMS Key"
  })
}

# KMS Key Alias - Disabled due to permissions
resource "aws_kms_alias" "eks" {
  count = 0  # Disabled - var.enable_encryption_at_rest ? 1 : 0
  
  name          = "alias/${var.cluster_name}-encryption"
  target_key_id = aws_kms_key.eks[0].key_id
}

# =============================================================================
# ELASTICSEARCH NAMESPACE
# =============================================================================

# Create namespace for Elasticsearch
resource "kubernetes_namespace" "elasticsearch" {
  
  metadata {
    name = "elasticsearch"
    labels = {
      name = "elasticsearch"
      environment = var.environment
    }
  }
  
  depends_on = [aws_eks_cluster.main]
}

# =============================================================================
# ELASTICSEARCH HELM RELEASE
# =============================================================================

# Elasticsearch Helm Release
resource "helm_release" "elasticsearch" {
  name       = "elasticsearch"
  repository = "https://helm.elastic.co"
  chart      = "elasticsearch"
  version    = "8.5.1"  # Helm chart version (not Elasticsearch version)
  namespace  = kubernetes_namespace.elasticsearch.metadata[0].name
  
  values = [
    yamlencode({
      # Basic configuration
      clusterName = "${var.cluster_name}-elasticsearch"
      nodeGroup = "default"
      
      # Node configuration
      replicas = var.elasticsearch_data_nodes
      
      # Resources
      resources = {
        requests = {
          memory = var.elasticsearch_heap_size
          cpu    = "500m"
        }
        limits = {
          memory = var.elasticsearch_heap_size
          cpu    = "2000m"
        }
      }
      
      # Storage
      volumeClaimTemplate = {
        spec = {
          accessModes = ["ReadWriteOnce"]
          resources = {
            requests = {
              storage = "100Gi"
            }
          }
          storageClassName = "gp3"
        }
      }
      
      # Security
      secretName = "elasticsearch-credentials"
      
      # Configuration
      esConfig = {
        "elasticsearch.yml" = yamlencode({
          "cluster.name" = "${var.cluster_name}-elasticsearch"
          "node.name"    = "elasticsearch-${var.cluster_name}"
          "network.host" = "0.0.0.0"
          "discovery.seed_hosts" = ["elasticsearch-${var.cluster_name}-0"]
          "cluster.initial_master_nodes" = ["elasticsearch-${var.cluster_name}-0"]
          
          # Security settings
          "xpack.security.enabled" = var.enable_security
          "xpack.security.transport.ssl.enabled" = var.enable_encryption_in_transit
          "xpack.security.http.ssl.enabled" = var.enable_encryption_in_transit
          
          # Performance settings
          "indices.memory.index_buffer_size" = "30%"
          "thread_pool.write.size" = 32
          "thread_pool.read.size" = 32
        })
      }
      
      # Service configuration
      service = {
        type = "ClusterIP"
        annotations = {
          "service.beta.kubernetes.io/aws-load-balancer-type" = "nlb"
        }
      }
    })
  ]
  
  depends_on = [
    kubernetes_namespace.elasticsearch,
    aws_eks_node_group.main
  ]
}

# =============================================================================
# ELASTICSEARCH CREDENTIALS SECRET
# =============================================================================

# Generate random password for Elasticsearch
resource "random_password" "elasticsearch" {
  length  = 32
  special = true
}

# Create Kubernetes secret for Elasticsearch credentials
resource "kubernetes_secret" "elasticsearch_credentials" {
  metadata {
    name      = "elasticsearch-credentials"
    namespace = kubernetes_namespace.elasticsearch.metadata[0].name
  }
  
  data = {
    username = "elastic"
    password = random_password.elasticsearch.result
  }
  
  depends_on = [kubernetes_namespace.elasticsearch]
}

# =============================================================================
# ELASTICSEARCH SERVICE
# =============================================================================

# External service for Elasticsearch access
resource "kubernetes_service" "elasticsearch_external" {
  metadata {
    name      = "elasticsearch-external"
    namespace = kubernetes_namespace.elasticsearch.metadata[0].name
    annotations = {
      "service.beta.kubernetes.io/aws-load-balancer-type" = "nlb"
      "service.beta.kubernetes.io/aws-load-balancer-scheme" = "internal"
    }
  }
  
  spec {
    type = "LoadBalancer"
    port {
      port        = 9200
      target_port = 9200
      protocol    = "TCP"
    }
    
    selector = {
      "app.kubernetes.io/name" = "elasticsearch"
      "app.kubernetes.io/instance" = "elasticsearch"
    }
  }
  
  depends_on = [helm_release.elasticsearch]
}
