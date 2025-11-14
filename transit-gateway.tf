#Transit Gateway
resource "aws_ec2_transit_gateway" "tgw" {
  description                     = "main-tgw"
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  lifecycle {
    create_before_destroy = true
  }
}

#Transit Gateway Attachment - Subnets VPCA
resource "aws_ec2_transit_gateway_vpc_attachment" "subnets_vpca" {
  subnet_ids = [
    aws_subnet.public_subnet_vpca.id,
    aws_subnet.public_subnet_b_vpca.id,
    aws_subnet.private_subnet_web1_vpca,
    aws_subnet.private_subnet_web2_vpca
  ]
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  vpc_id             = aws_vpc.vpca.id
}
#Transit Gateway Attachment - Subnets VPCB
resource "aws_ec2_transit_gateway_vpc_attachment" "subnets_vpcb" {
  subnet_ids         = [aws_subnet.private_subnet_vpcb.id, aws_subnet.private_subnet_b_vpcb.id]
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  vpc_id             = aws_vpc.vpcb.id
}
#Transit Gateway Attachment - Subnets VPCC
resource "aws_ec2_transit_gateway_vpc_attachment" "subnets_vpcc" {
  subnet_ids         = [aws_subnet.private_subnet_vpcc.id]
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  vpc_id             = aws_vpc.vpcc.id
}

#Transit Gateway Route Table
resource "aws_ec2_transit_gateway_route_table" "tgw_route_table" {
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
}
#Transit Gateway Routes - VPCA
resource "aws_ec2_transit_gateway_route" "tgw_route_to_vpca" {
  destination_cidr_block         = "10.111.0.0/16"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.subnets_vpca.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgw_route_table.id
}
#Transit Gateway Routes - VPCB
resource "aws_ec2_transit_gateway_route" "tgw_route_to_vpcb" {
  destination_cidr_block         = "10.112.0.0/16"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.subnets_vpcb.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgw_route_table.id
}
#Transit Gateway Routes - VPCC
resource "aws_ec2_transit_gateway_route" "tgw_route_to_vpcc" {
  destination_cidr_block         = "10.113.0.0/16"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.subnets_vpcc.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgw_route_table.id
}

#Transit Gateway Association - VPCA
resource "aws_ec2_transit_gateway_route_table_association" "association_vpca" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.subnets_vpca.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgw_route_table.id
}
#Transit Gateway Association - VPCB
resource "aws_ec2_transit_gateway_route_table_association" "association_vpcb" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.subnets_vpcb.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgw_route_table.id
}
#Transit Gateway Association - VPCC
resource "aws_ec2_transit_gateway_route_table_association" "association_vpcc" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.subnets_vpcc.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgw_route_table.id
}

# VPN/BGP config for Transit Gateway
# ---Transit Gateway VPN Attachment---
data "aws_ec2_transit_gateway_vpn_attachment" "vpn_attachment" {
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  vpn_connection_id  = aws_vpn_connection.vpn.id # Reference existing VPN connection 
}

# ---Transit Gateway Association - VPN Attachment---
#ensures traffic coming from the VPN uses the tgw_route_table for routing
resource "aws_ec2_transit_gateway_route_table_association" "association_vpn" {
  transit_gateway_attachment_id  = data.aws_ec2_transit_gateway_vpn_attachment.vpn_attachment.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgw_route_table.id
}

/* UNCOMMENT IF USING BGP > THEN COMMENT: aws_ec2_transit_gateway_route.route_to_onprem */
# ---Transit Gateway Propagation - VPN Attachment---
# This enables BGP route propagation on-premises network to the tgw_route_table
resource "aws_ec2_transit_gateway_route_table_propagation" "propagation_vpn" {
  transit_gateway_attachment_id  = data.aws_ec2_transit_gateway_vpn_attachment.vpn_attachment.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgw_route_table.id
}

/*
# For static routing | on-prem network
resource "aws_ec2_transit_gateway_route" "route_to_onprem" {
  destination_cidr_block         = var.on-prem-cidr # on-prem subnet
  transit_gateway_attachment_id  = aws_vpn_connection.vpn.transit_gateway_attachment_id #data.aws_ec2_transit_gateway_vpn_attachment.vpn_attachment.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgw_route_table.id
}
*/