# Application Load Balancer
resource "aws_lb" "main" {
  name = "scalable-web-service-alb"
  internal = false
  load_balancer_type = "application"
  security_groups = [aws_security_group.alb.id]
  subnets = [aws_subnet.public_1.id, aws_subnet.public_2.id]

  tags = {
    Name = "scalable-web-service-alb"
  }
}

# Target Group
resource "aws_lb_target_group" "main" {
  name = "scalable-web-service-tg"
  port = 8080
  protocol = "HTTP"
  vpc_id = aws_vpc.main.id
  target_type = "ip"

  health_check {
    enabled = true
    healthy_threshold = 2
    unhealthy_threshold = 3
    timeout = 5
    interval = 30
    path = "/health"
    matcher = "200"
  }

  tags = {
    Name = "scalable-web-service-tg"
  }
}

# HTTP Listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port = 80
  protocol = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}