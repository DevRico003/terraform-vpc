locals {
  azs       = ["${var.region}a", "${var.region}b", "${var.region}c"]
  cidrs     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"] 
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "TF VPC"
  }
}

resource "aws_subnet" "subnet" {
  count             = length(local.azs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = local.cidrs[count.index]
  availability_zone = local.azs[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "TF Subnet ${count.index}"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "TF Internet Gateway"
  }
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "TF Route Table"
  }
}

resource "aws_route_table_association" "rta" {
  count          = length(local.azs)
  subnet_id      = aws_subnet.subnet[count.index].id
  route_table_id = aws_route_table.rt.id
}

resource "aws_security_group" "sg" {
  name        = "tf_sg"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "test_instance" {
  count = length(local.azs)

  ami                         = "ami-065ab11fbd3d0323d" # Ersetzen Sie dies durch eine geeignete AMI-ID für Ihre Region
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.subnet[count.index].id
  vpc_security_group_ids      = [aws_security_group.sg.id]

  tags = {
    Name = "Test Instance in Subnet ${count.index}"
  }
}
