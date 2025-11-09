resource "aws_eks_cluster" "eks_cluster1" { #eks 클러스터 생성
    name = var.eks_cluster_1
    role_arn = aws_iam_role.eks_cluster_role.arn
    version = "1.30"

        
    vpc_config {
      endpoint_private_access = true
      endpoint_public_access = true
      subnet_ids = [
        aws_subnet.private_1a.id,
        aws_subnet.private_2b.id,
        aws_subnet.private_3c.id
        ]
      security_group_ids = [aws_security_group.sg_eks_cluster.id,]

    }
    depends_on = [ 
      aws_iam_role_policy_attachment.eks_cluster_policy,
      aws_iam_role_policy_attachment.eks_vpc_controller
     ]

}

resource "aws_eks_node_group" "eks_node1" { #노드그룹 생성
    cluster_name = aws_eks_cluster.eks_cluster1.name
    node_group_name = "eks_node1"
    node_role_arn = aws_iam_role.eks_node_role.arn
    subnet_ids = [
        aws_subnet.private_1a.id,
        aws_subnet.private_2b.id,
        aws_subnet.private_3c.id
    ]

    scaling_config {
      desired_size = var.eks_cluster1_desired_node_count #3
      min_size = var.eks_cluster1_min_node_count #3
      max_size = var.eks_cluster1_max_node_count #6
    }
    instance_types = ["m5.large"]
    disk_size = 30
    capacity_type = "ON_DEMAND"

    depends_on = [ 
      aws_iam_role_policy_attachment.node_worker,
      aws_iam_role_policy_attachment.node_cni,
      aws_iam_role_policy_attachment.node_ecr_ro,
      aws_iam_role_policy_attachment.node_ssm
     ]


}


# 에드온
# (1) 애드온 버전 조회 – 클러스터 버전에 맞춰 가장 최신
data "aws_eks_addon_version" "vpc_cni" {
  addon_name         = "vpc-cni"
  kubernetes_version = aws_eks_cluster.eks_cluster1.version
  most_recent        = true
}
data "aws_eks_addon_version" "kube_proxy" {
  addon_name         = "kube-proxy"
  kubernetes_version = aws_eks_cluster.eks_cluster1.version
  most_recent        = true
}
data "aws_eks_addon_version" "coredns" {
  addon_name         = "coredns"
  kubernetes_version = aws_eks_cluster.eks_cluster1.version
  most_recent        = true
}

# (2) 애드온 리소스 – OIDC/IRSA 없이
resource "aws_eks_addon" "vpc_cni" {
  cluster_name  = aws_eks_cluster.eks_cluster1.name
  addon_name    = "vpc-cni"
  addon_version = data.aws_eks_addon_version.vpc_cni.version

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  depends_on = [aws_eks_node_group.eks_node1]  # 노드 먼저
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name  = aws_eks_cluster.eks_cluster1.name
  addon_name    = "kube-proxy"
  addon_version = data.aws_eks_addon_version.kube_proxy.version

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  depends_on = [aws_eks_node_group.eks_node1]
}

resource "aws_eks_addon" "coredns" {
  cluster_name  = aws_eks_cluster.eks_cluster1.name
  addon_name    = "coredns"
  addon_version = data.aws_eks_addon_version.coredns.version

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  depends_on = [aws_eks_node_group.eks_node1]
}