#LB - Internet Facing
resource "aws_lb" "lba" {
  name               = "lba-internet"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lba.id]
  subnets            = [aws_subnet.public_subnet_vpca.id, aws_subnet.public_subnet_b_vpca.id]
}
resource "aws_lb_target_group" "tg_a" {
  name     = "tg-a"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpca.id
}

resource "aws_lb_listener" "lba_https" {
  load_balancer_arn = aws_lb.lba.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate_validation.alb_cert_validation.certificate_arn
  default_action {
    type = "forward"
    forward {
      target_group {
        arn    = aws_lb_target_group.tg_a.arn
        weight = 100
      }
    }
  }
}

resource "aws_autoscaling_attachment" "asg_lba" {
  autoscaling_group_name = aws_autoscaling_group.asg_1.id
  lb_target_group_arn    = aws_lb_target_group.tg_a.arn
}