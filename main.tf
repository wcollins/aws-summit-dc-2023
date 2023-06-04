locals {

  # VPC CIDR blocks
  vpcs = {
    dev     = "10.1.0.0/16"
    stage   = "10.2.0.0/16"
    prod    = "10.3.0.0/16"
    shared  = "10.4.0.0/16"
  }

}

/*
Provision each VPC
https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc
*/
resource "aws_vpc" "this" {
  for_each = local.vpcs

  cidr_block = each.value 

  tags = {
    Name = each.key
  }

}

/*
Provision a single /24 subnet per VPC
https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet
*/
resource "aws_subnet" "this" {
  for_each          = aws_vpc.this
  vpc_id            = each.value.id

  cidr_block        = cidrsubnet(each.value.cidr_block, 8, 0)
  availability_zone = "${var.aws_region}a"

  tags = {
    Name = "${each.key}-subnet"
  }

}

/*
Provision a Transit Gateway
https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway
*/
resource "aws_ec2_transit_gateway" "this" {

   # Disable association with default route table
  default_route_table_association = "disable"

  # Disable propagation to default route table
  default_route_table_propagation = "disable"

  tags = {
    Name = format("tgw-%s", var.aws_region)
  }

}

/*
Attach each VPC to Transit Gateway / Disable default route table association + propagation
https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_vpc_attachment
*/
resource "aws_ec2_transit_gateway_vpc_attachment" "this" {
  for_each           = aws_vpc.this

  # Disable association with default route table
  transit_gateway_default_route_table_association = false

  # Disable propagation to default route table
  transit_gateway_default_route_table_propagation = false

  vpc_id             = each.value.id
  subnet_ids         = [aws_subnet.this[each.key].id]
  transit_gateway_id = aws_ec2_transit_gateway.this.id

  tags = {
    Name = "${each.key}-tgw-attach"
  }

}

resource "aws_internet_gateway" "this" {
  for_each = aws_vpc.this

  vpc_id = each.value.id

  tags = {
    Name = "${each.key}-igw"
  }

}

resource "aws_route_table" "this" {
  for_each = aws_vpc.this

  vpc_id = each.value.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this[each.key].id
  }

  tags = {
    Name = "${each.key}-rt"
  }

}

resource "aws_route_table_association" "this" {
  for_each          = aws_subnet.this
  subnet_id         = each.value.id
  route_table_id    = aws_route_table.this[each.key].id
}

resource "random_id" "this" {
  byte_length = 8
}

resource "aws_key_pair" "this" {
  key_name   = random_id.this.hex
  public_key = file(var.public_key)
}

resource "aws_instance" "this" {
  for_each                     = aws_subnet.this
  ami                          = var.ami
  instance_type                = "t2.micro"
  key_name                     = aws_key_pair.this.key_name
  subnet_id                    = each.value.id
  vpc_security_group_ids       = [aws_security_group.this[each.key].id]
  associate_public_ip_address  = true

  tags = {
    Name = "${each.key}-instance"
  }

}

resource "aws_security_group" "this" {
  for_each = aws_vpc.this

  name   = "${each.key}-allow-ssh"
  vpc_id = each.value.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = var.ingress_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}