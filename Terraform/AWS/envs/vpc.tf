# 퍼블릭 서브넷 

resource "aws_subnet" "public_1a" { # 퍼블릭1a 서브넷 생성
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-northeast-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "eks-public"
    "kubernetes.io/role/elb" = "1"
    "kubernetes.io/cluster/eks_cluster1" = "shared"

  }
}


# 프라이빗 서브넷 

resource "aws_subnet" "private_1a" { # 프라이빗1a 서브넷 생성
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.10.0/24"
  availability_zone       = "ap-northeast-2a"
  map_public_ip_on_launch = false
  
  tags = {
    Name = "main-private-subnet-1a"
    "kubernetes.io/cluster/eks_cluster1" = "shared"
    "kubernetes.io/role/internal-elb"    = "1"
  }
}

resource "aws_subnet" "private_2b" { # 프라이빗2b 서브넷 생성
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.11.0/24"
  availability_zone       = "ap-northeast-2b"
  map_public_ip_on_launch = false

  tags = {
    Name = "main-private-subnet-2b"
    "kubernetes.io/cluster/eks_cluster1" = "shared"
    "kubernetes.io/role/internal-elb"    = "1"
  }
}

#IGW 

resource "aws_internet_gateway" "igw1"{ #internet_GW1 생성
    vpc_id = aws_vpc.main.id

    tags = {
        Name = "main-igw1"
    }
}


#1a
#Elastic IP + NAT GW

resource "aws_eip" "eip_1a" { #eip_1a 생성
    domain = "vpc"
    
    tags = {
        Name = "main-eip-1a"
    }
}

resource "aws_nat_gateway" "nat_1a" { #NAT_GW_1a 생성
    allocation_id = aws_eip.eip_1a.id
    subnet_id = aws_subnet.public_1a.id
    
    tags = {
        Name = "main-nat-1a"
    }
}

#Routing Table

resource "aws_route_table" "RT_public_1a" { #퍼블릭1a 서브넷 > IGW 라우팅
    vpc_id = aws_vpc.main.id
    
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw1.id
    }
    tags = {
        Name = "main-RT-public-1a"
    }
  
}
resource "aws_route_table_association" "RT_public_ass_1a" { #퍼블릭1a 서브넷 라우팅 테이블 연결
    subnet_id = aws_subnet.public_1a.id
    route_table_id = aws_route_table.RT_public_1a.id

}
resource "aws_route_table" "RT_private_1a" { #프라이빗1a 서브넷 > nat1a 라우팅
    vpc_id = aws_vpc.main.id
    route{
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.nat_1a.id
    }

    tags = {
        Name = "main-RT-private-1a"
    }
}
resource "aws_route_table_association" "RT_private_ass_1a" { #프라이빗1a 서브넷 라우팅 테이블 연결
    subnet_id = aws_subnet.private_1a.id
    route_table_id = aws_route_table.RT_private_1a.id
}



#2b

#Routing Table

resource "aws_route_table" "RT_private_2b" { #프라이빗2b 서브넷 >  nat1a 라우팅
    vpc_id = aws_vpc.main.id
    route{
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.nat_1a.id
    }

    tags = {
        Name = "main-RT-private-2b"
    }
}
resource "aws_route_table_association" "RT_private_ass_2b" { #프라이빗2b 서브넷 라우팅 테이블 연결
    subnet_id = aws_subnet.private_1a.id
    route_table_id = aws_route_table.RT_private_1a.id
}
