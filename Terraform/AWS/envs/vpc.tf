resource "aws_subnet" "main_public_subnet" {
  for_each = {
    "1a" = var.public_subnets[0]
    "1b" = var.public_subnets[1]
    "1c" = var.public_subnets[2]
  }
  
  vpc_id               = aws_vpc_.main.id
  cidr_block           = each.value
  availability_zone    = var.region

  tags = {
    name = "main_public_subnet"
  }
}


