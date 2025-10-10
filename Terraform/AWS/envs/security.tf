# 보안그룹

resource "aws_security_group" "sg_alb" { # alb SG
    name = "sg_alb"
    description = "aws-main-alb-sg"
    vpc_id = aws_vpc.main.id

    # 인바운드 > cloudflare IP로  범위제한
    ingress { # 80 허용
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    
    ingress { # 443 허용
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
     }

    # 아웃바운드 전체 허용
    egress { #줄이기
        from_port   = 0
        to_port     = 0
        protocol    = "-1"   
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = { Name = "sg-alb" }

}

#EKS

resource "aws_security_group" "sg_eks_cluster" { #컨트롤플레인 ENI SG
    name = "sg_eks_cluster"
    vpc_id = aws_vpc.main.id
    
    egress { #줄이기
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
        description = "General egress"
    }

    tags = { Name = "sg_eks_cluster" }
}

resource "aws_security_group" "sg_eks_nodes" { #워커 노드 SG
    name = "sg_eks_nodes"
    vpc_id = aws_vpc.main.id

    ingress {    
        from_port = 30000
        to_port = 32767
        protocol = "tcp"
        security_groups = [aws_security_group.sg_alb.id]
        description = "ALB > NodePort"
    }
    ingress {
        from_port = 10250
        to_port = 10250
        protocol = "tcp"
        security_groups = [aws_security_group.sg_eks_cluster.id] 
        description = "Cluster > Nodes (kubelet)"
    }
    ingress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        self = true
        description = "node-to-node"
    }

    egress { #줄이기
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = { Name = "sg_eks_nodes" }
}


#RDS / Aurora 
resource "aws_security_group" "sg_rds" {
    name = "sg_rds"
    description = "aws-main-db-sg"
    vpc_id = aws_vpc.main.id
    
    ingress {
        from_port = 5432
        to_port = 5432
        protocol = "tcp"
        security_groups = [aws_security_group.sg_eks_nodes]
        description = "eks_nodes > db"
    }

    egress { #줄이기
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = { Name = "sg_rds" }
}