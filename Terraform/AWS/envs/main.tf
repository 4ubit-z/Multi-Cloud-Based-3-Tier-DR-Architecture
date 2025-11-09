resource "aws_vpc" "main" { # main vpc 생성
  cidr_block = var.vpc_1_cidr #10.0.0.0/16

  tags = {
    Name = "aws-main-vpc"
  }
}