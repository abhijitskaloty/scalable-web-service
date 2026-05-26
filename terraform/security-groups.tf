# Security group for the Load Balancer
resource "aws_security_group" "alb" {
  name = "scalable-web-service-alb-sg"
  description = "Allow HTTP from internet"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "scalable-web-service-alb-sg"
  }
}

# Security group for ECS tasks
resource "aws_security_group" "ecs" {
  name = "scalable-web-service-ecs-sg"
  description = "Allow traffic from ALB only"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "scalable-web-service-ecs-sg"
  }
}