# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "scalable-web-service-cluster"

  setting {
    name = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "scalable-web-service-cluster"
  }
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "main" {
  name = "/ecs/scalable-web-service"
  retention_in_days = 7

  tags = {
    Name = "scalable-web-service-logs"
  }
}

# ECS Task Definition
resource "aws_ecs_task_definition" "main" {
  family = "scalable-web-service"
  network_mode = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu = "256"
  memory = "512"
  execution_role_arn = aws_iam_role.ecs_execution.arn
  task_role_arn = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name = "scalable-web-service"

      # Public demo Go app used for testing infrastructure scaling
      # Source: https://github.com/therealdwright/scalable-web-service
      image = "ghcr.io/therealdwright/scalable-web-service:v1"

      essential = true

      portMappings = [
        {
          containerPort = 8080
          protocol = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group" = "/ecs/scalable-web-service"
          "awslogs-region" = "us-east-1"
          "awslogs-stream-prefix" = "ecs"
        }
      }

      healthCheck = {
        command = ["CMD-SHELL", "wget -q -O- http://localhost:8080/health || exit 1"]
        interval = 30
        timeout = 5
        retries = 3
        startPeriod = 10
      }
    }
  ])

  tags = {
    Name = "scalable-web-service-task"
  }
}

# ECS Service
resource "aws_ecs_service" "main" {
  name = "scalable-web-service"
  cluster = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.main.arn
  desired_count = 2
  launch_type = "FARGATE"

  network_configuration {
    subnets = [aws_subnet.public_1.id, aws_subnet.public_2.id]
    security_groups = [aws_security_group.ecs.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.main.arn
    container_name = "scalable-web-service"
    container_port = 8080
  }

  depends_on = [
    aws_lb_listener.http,
    aws_iam_role_policy_attachment.ecs_execution
  ]

  tags = {
    Name = "scalable-web-service"
  }
}
