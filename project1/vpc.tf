
resource "aws_vpc" "vpc_terraform" {
  cidr_block       = "10.0.0.0/16"
  tags = {
    Name = "vpc_terraform"
  }
}

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.vpc_terraform.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "public"
  }
}

resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.vpc_terraform.id
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "private"
  }
}