# 보안그룹

resource "aws_security_group" "sg_alb" {
    name = "sg_alb"
    description = "aws-main-alb-sg"
    vpc_id = aws_vpc.main.id
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
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"   
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = { Name = "sg-alb" }
    
}