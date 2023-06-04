/*
Add route to RFC1918 via Transit Gateway for each VPC
https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route
*/
resource "aws_route" "to_tgw" {
  for_each                = aws_route_table.this
  destination_cidr_block  = "10.0.0.0/8"
  route_table_id          = each.value.id
  transit_gateway_id      = aws_ec2_transit_gateway.this.id

  depends_on = [
    aws_ec2_transit_gateway.this,
    aws_ec2_transit_gateway_vpc_attachment.this
  ]

}

/*
Provision TGW route tables for additional traffic segmentation
https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_route_table
*/
resource "aws_ec2_transit_gateway_route_table" "this" {
  for_each           = aws_vpc.this
  transit_gateway_id = aws_ec2_transit_gateway.this.id

  tags = {
    Name = "${each.key}-tgw-rt"
  }

  depends_on = [
    aws_ec2_transit_gateway.this,
    aws_ec2_transit_gateway_vpc_attachment.this
  ]

}

# Attachments get a 1:1 mapping to a route table
resource "aws_ec2_transit_gateway_route_table_association" "this" {
  for_each                        = aws_vpc.this
  transit_gateway_attachment_id   = aws_ec2_transit_gateway_vpc_attachment.this[each.key].id
  transit_gateway_route_table_id  = aws_ec2_transit_gateway_route_table.this[each.key].id
}

# Propagate routes for production segment
resource "aws_ec2_transit_gateway_route_table_propagation" "prod_to_shared" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.this["shared"].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.this["prod"].id
}

# Propagate routes for shared service segment
resource "aws_ec2_transit_gateway_route_table_propagation" "shared_to_dev" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.this["dev"].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.this["shared"].id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "shared_to_stage" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.this["stage"].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.this["shared"].id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "shared_to_prod" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.this["prod"].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.this["shared"].id
}

# Propagate routes for non-production segments
resource "aws_ec2_transit_gateway_route_table_propagation" "dev_to_stage" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.this["stage"].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.this["dev"].id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "dev_to_shared" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.this["shared"].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.this["dev"].id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "stage_to_dev" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.this["dev"].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.this["stage"].id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "stage_to_shared" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.this["shared"].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.this["stage"].id
}