#VPCB
resource "aws_instance" "amazon_linux_vpcb" {
  ami             = var.amazon_linux_2023
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.vpcb.id]
  subnet_id       = aws_subnet.private_subnet_vpcb.id
  key_name        = aws_key_pair.ec2_key.key_name

}
#VPCC
resource "aws_instance" "amazon_linux_vpcc" {
  ami             = var.amazon_linux_2023
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.vpcc.id]
  subnet_id       = aws_subnet.private_subnet_vpcc.id
  key_name        = aws_key_pair.ec2_key.key_name

}