resource "aws_vpc" "main" { # main vpc 생성
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "aws-main-vpc"
  }
}