resource "aws_eks_cluster" "eks_cluster1" { #eks 클러스터 생성
    name = var.eks_cluster_1
    role_arn = var.sso_role_name
    version = "1.30"

        
    vpc_config {
      endpoint_private_access = true
      endpoint_public_access = true
      subnet_ids = [
        aws_subnet.private_1a.id,
        aws_subnet.private_2b.id,
        aws_subnet.private_3c.id
        ]
      security_group_ids = [aws_security_group.sg_eks_cluster.id]

    }
}

resource "aws_eks_node_group" "eks_node1" { #노드그룹 생성
    cluster_name = aws_eks_cluster.eks_cluster1.name
    node_group_name = "eks_node1"
    node_role_arn = var.sso_role_name
    subnet_ids = [
        aws_subnet.private_1a.id,
        aws_subnet.private_2b.id,
        aws_subnet.private_3c.id
    ]

    scaling_config {
      desired_size = 3
      min_size = 3
      max_size = 6
    }
    instance_types = ["t3.medium"]
    disk_size = 30

}