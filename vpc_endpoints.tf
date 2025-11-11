#Secrets Manager VPC Endpoint
resource "aws_vpc_endpoint" "secrets_manager" {
  vpc_id            = aws_vpc.vpca.id
  service_name      = "com.amazonaws.${var.region1}.secretsmanager"
  vpc_endpoint_type = "Interface"
  subnet_ids = [
    aws_subnet.public_subnet_vpca.id,
  ]
  security_group_ids  = [aws_security_group.secrets_manager.id]
  private_dns_enabled = true
}