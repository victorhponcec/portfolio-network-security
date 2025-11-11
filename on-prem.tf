#VPCA
resource "aws_vpc" "onprem" {
  cidr_block = "10.222.0.0/16"
  tags       = { Name = "onprem" }
}

resource "aws_subnet" "public_subnet_onprem" {
  vpc_id            = aws_vpc.onprem.id
  cidr_block        = "10.222.1.0/24"
  availability_zone = "us-east-1a"
  tags              = { Name = "onprem" }
}

#Internet Gateway
resource "aws_internet_gateway" "igw_onprem" {
  vpc_id = aws_vpc.onprem.id
}

#Route Table
resource "aws_route_table" "public_rtb_onprem" {
  vpc_id = aws_vpc.onprem.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_onprem.id
  }
}

#Associate public Subnet to public route table
resource "aws_route_table_association" "public_onprem" {
  subnet_id      = aws_subnet.public_subnet_onprem.id
  route_table_id = aws_route_table.public_rtb_onprem.id
}

#EC2 Instances - On-prem
resource "aws_instance" "ubuntu_onprem" {
  ami                         = "ami-020cba7c55df1f615" #ubuntu 24.04
  instance_type               = "t2.micro"
  security_groups             = [aws_security_group.ssh_onprem.id]
  subnet_id                   = aws_subnet.public_subnet_onprem.id
  associate_public_ip_address = true
  key_name                    = aws_key_pair.ec2_key.key_name
}

#==== Security Group ===#
resource "aws_security_group" "ssh_onprem" {
  name        = "ssh_onprem"
  description = "allow SSH"
  vpc_id      = aws_vpc.onprem.id
}

#Ingress rule for SSH
resource "aws_vpc_security_group_ingress_rule" "allow_ssh_onprem" {
  security_group_id = aws_security_group.ssh_onprem.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
}
resource "aws_vpc_security_group_ingress_rule" "allow_icmp_onprem" {
  security_group_id = aws_security_group.ssh_onprem.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = -1
  to_port           = -1
  ip_protocol       = "icmp"
}
#Ports UPD 500 (IKEv1v2) and 4500 (NAT traversal) to stablish VPN
resource "aws_vpc_security_group_ingress_rule" "allow_udp_500" {
  security_group_id = aws_security_group.ssh_onprem.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 500
  to_port           = 500
  ip_protocol       = "udp"
}
resource "aws_vpc_security_group_ingress_rule" "allow_udp_4500" {
  security_group_id = aws_security_group.ssh_onprem.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 4500
  to_port           = 4500
  ip_protocol       = "udp"
}
#Egress rule for SSH
resource "aws_vpc_security_group_egress_rule" "egress_ssh_all_onprem" {
  security_group_id = aws_security_group.ssh_onprem.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}