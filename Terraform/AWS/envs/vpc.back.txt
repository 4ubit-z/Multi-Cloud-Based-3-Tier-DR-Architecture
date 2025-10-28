# 퍼블릭 서브넷 

resource "aws_subnet" "public_1a" { # 퍼블릭1a 서브넷 생성
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-northeast-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "main-public-subnet-1a"
  }
}

resource "aws_subnet" "public_2b" { # 퍼블릭2b 서브넷 생성
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "ap-northeast-2b"
  map_public_ip_on_launch = true

  tags = {
    Name = "main-public-subnet-2b"
  }
}

resource "aws_subnet" "public_3c" { # 퍼블릭3c 서브넷 생성
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "ap-northeast-2c"
  map_public_ip_on_launch = true

  tags = {
    Name = "main-public-subnet-3c"
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
  }
}

resource "aws_subnet" "private_2b" { # 프라이빗2b 서브넷 생성
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.11.0/24"
  availability_zone       = "ap-northeast-2b"
  map_public_ip_on_launch = false

  tags = {
    Name = "main-private-subnet-2b"
  }
}

resource "aws_subnet" "private_3c" { # 프라이빗3c 서브넷 생성
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.12.0/24"
  availability_zone       = "ap-northeast-2c"
  map_public_ip_on_launch = false

  tags = {
    Name = "main-private-subnet-3c"
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
resource "aws_route_table" "RT_private_1a" { #프라이빗1a 서브넷 > 퍼블릭1a 서브넷 라우팅
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
#Elastic IP + NAT GW
resource "aws_eip" "eip_2b" { #eip_2b 생성
    domain = "vpc"
    
    tags = {
        Name = "main-eip-2b"
    }
}
resource "aws_nat_gateway" "nat_2b" { #NAT_GW_1a 생성
    allocation_id = aws_eip.eip_2b.id
    subnet_id = aws_subnet.public_2b.id
    
    tags = {
        Name = "main-nat-2b"
    }
}

#Routing Table
resource "aws_route_table" "RT_public_2b" { #퍼블릭2b 서브넷 > IGW 라우팅
    vpc_id = aws_vpc.main.id
    
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw1.id
    }
    tags = {
        Name = "main-RT-public-2b"
    }
}
resource "aws_route_table_association" "RT_public_ass_2b" { #퍼블릭2b 서브넷 라우팅 테이블 연결
    subnet_id = aws_subnet.public_2b.id
    route_table_id = aws_route_table.RT_public_2b.id
}

resource "aws_route_table" "RT_private_2b" { #프라이빗2b 서브넷 > 퍼블릭2b 서브넷 라우팅
    vpc_id = aws_vpc.main.id
    route{
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.nat_2b.id
    }

    tags = {
        Name = "main-RT-private-2b"
    }
}
resource "aws_route_table_association" "RT_private_ass_2b" { #프라이빗2b 서브넷 라우팅 테이블 연결
    subnet_id = aws_subnet.private_2b.id
    route_table_id = aws_route_table.RT_private_2b.id
}

#3c
#Elastic IP + NAT GW
resource "aws_eip" "eip_3c" { #eip_3c 생성
    domain = "vpc"
    
    tags = {
        Name = "main-eip-3c"
    }
}
resource "aws_nat_gateway" "nat_3c" { #NAT_GW_1a 생성
    allocation_id = aws_eip.eip_3c.id
    subnet_id = aws_subnet.public_3c.id
    
    tags = {
        Name = "main-nat-3c"
    }
}

#Routing Table
resource "aws_route_table" "RT_public_3c" { #퍼블릭1a 서브넷 > IGW 라우팅
    vpc_id = aws_vpc.main.id
    
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw1.id
    }
    tags = {
        Name = "main-RT-public-3c"
    }
}
resource "aws_route_table_association" "RT_public_ass_3c" { #퍼블릭3c 서브넷 라우팅 테이블 연결
    subnet_id = aws_subnet.public_3c.id
    route_table_id = aws_route_table.RT_public_3c.id
}

resource "aws_route_table" "RT_private_3c" { #프라이빗3c 서브넷 > 퍼블릭3c 서브넷 라우팅
    vpc_id = aws_vpc.main.id
    route{
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.nat_3c.id
    }

    tags = {
        Name = "main-RT-private-3c"
    }
}
resource "aws_route_table_association" "RT_private_ass_3c" { #프라이빗3c 서브넷 라우팅 테이블 연결
    subnet_id = aws_subnet.private_3c.id
    route_table_id = aws_route_table.RT_private_3c.id
}