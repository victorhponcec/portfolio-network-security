#SG LBA
resource "aws_security_group" "lba" {
  name        = "lba_web"
  description = "allow web traffic"
  vpc_id      = aws_vpc.vpca.id
}
resource "aws_vpc_security_group_ingress_rule" "lba_allow_443" {
  security_group_id = aws_security_group.lba.id
  prefix_list_id    = data.aws_ec2_managed_prefix_list.cloudfront.id
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}
data "aws_ec2_managed_prefix_list" "cloudfront" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}

resource "aws_vpc_security_group_egress_rule" "lba_egress_all" {
  security_group_id = aws_security_group.lba.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

#Security group VPCA
resource "aws_security_group" "vpca" {
  name        = "vpca"
  description = "allow SSH,ICMP"
  vpc_id      = aws_vpc.vpca.id
}
resource "aws_vpc_security_group_ingress_rule" "web_443_allow_vpca" {
  security_group_id            = aws_security_group.vpca.id
  referenced_security_group_id = aws_security_group.lba.id
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
}
resource "aws_vpc_security_group_ingress_rule" "web_80_allow_vpca" {
  security_group_id            = aws_security_group.vpca.id
  referenced_security_group_id = aws_security_group.lba.id
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
}
resource "aws_vpc_security_group_ingress_rule" "allow_vpca" {
  for_each          = toset(local.allowed_cidrs_VPCA)
  security_group_id = aws_security_group.vpca.id
  cidr_ipv4         = each.value
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
}
resource "aws_vpc_security_group_ingress_rule" "allow_icmp_vpca" {
  for_each          = toset(local.allowed_cidrs_VPCA)
  security_group_id = aws_security_group.vpca.id
  cidr_ipv4         = each.value
  from_port         = -1
  to_port           = -1
  ip_protocol       = "icmp"
}
resource "aws_vpc_security_group_egress_rule" "egress_all_vpca" {
  security_group_id = aws_security_group.vpca.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

#Security group VPCB
resource "aws_security_group" "vpcb" {
  name        = "vpcb"
  description = "allow SSH,ICMP"
  vpc_id      = aws_vpc.vpcb.id
}
resource "aws_vpc_security_group_ingress_rule" "web_443_allow_vpcb" {
  security_group_id            = aws_security_group.vpcb.id
  referenced_security_group_id = aws_security_group.lba.id
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
}
resource "aws_vpc_security_group_ingress_rule" "web_80_allow_vpcb" {
  security_group_id            = aws_security_group.vpcb.id
  referenced_security_group_id = aws_security_group.lba.id
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
}
resource "aws_vpc_security_group_ingress_rule" "allow_vpcb" {
  for_each          = toset(local.allowed_cidrs_VPCB)
  security_group_id = aws_security_group.vpcb.id
  cidr_ipv4         = each.value
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
}
resource "aws_vpc_security_group_ingress_rule" "allow_icmp_vpcb" {
  for_each          = toset(local.allowed_cidrs_VPCB)
  security_group_id = aws_security_group.vpcb.id
  cidr_ipv4         = each.value
  from_port         = -1
  to_port           = -1
  ip_protocol       = "icmp"
}
resource "aws_vpc_security_group_egress_rule" "egress_ssh_all_vpcb" {
  security_group_id = aws_security_group.vpcb.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}
#Security group VPCC
resource "aws_security_group" "vpcc" {
  name        = "vpcc"
  description = "allow SSH,ICMP"
  vpc_id      = aws_vpc.vpcc.id
}
resource "aws_vpc_security_group_ingress_rule" "allow_vpcc" {
  for_each          = toset(local.allowed_cidrs_VPCC)
  security_group_id = aws_security_group.vpcc.id
  cidr_ipv4         = each.value
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
}
resource "aws_vpc_security_group_ingress_rule" "allow_icmp_vpcc" {
  for_each          = toset(local.allowed_cidrs_VPCC)
  security_group_id = aws_security_group.vpcc.id
  cidr_ipv4         = each.value
  from_port         = -1
  to_port           = -1
  ip_protocol       = "icmp"
}
resource "aws_vpc_security_group_egress_rule" "egress_ssh_all_vpcc" {
  security_group_id = aws_security_group.vpcc.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

#SG DB 
resource "aws_security_group" "db" {
  name        = "db-sg"
  description = "allow db access from VPCA-VPCC"
  vpc_id      = aws_vpc.vpcb.id

  ingress {
    description = "Allow MySQL from subnets"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [
      aws_subnet.private_subnet_vpcc.cidr_block,
      aws_subnet.public_subnet_vpca.cidr_block
    ]
  }
}

#SG Secrets Manager Endpoint
resource "aws_security_group" "secrets_manager" {
  name        = "secrets_manager"
  description = "allow app traffic to secrets manager"
  vpc_id      = aws_vpc.vpca.id
}
resource "aws_vpc_security_group_ingress_rule" "secrets_manager_app_allow_443" {
  security_group_id            = aws_security_group.secrets_manager.id
  referenced_security_group_id = aws_security_group.vpca.id
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
}