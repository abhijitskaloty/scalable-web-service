# CloudFront HTTPS URL
output "cloudfront_url" {
  description = "CloudFront HTTPS URL - use this to access the service"
  value = "https://${aws_cloudfront_distribution.main.domain_name}"
}

# ALB URL (internal HTTP endpoint, used by CloudFront)
output "alb_url" {
  description = "ALB HTTP URL (internal - CloudFront connects to this)"
  value       = "http://${aws_lb.main.dns_name}"
}

# ECS Cluster name
output "ecs_cluster_name" {
  description = "ECS Cluster name"
  value = aws_ecs_cluster.main.name
}

# ECS Service name
output "ecs_service_name" {
  description = "ECS Service name"
  value = aws_ecs_service.main.name
}

# CloudWatch Log Group
output "cloudwatch_log_group" {
  description = "CloudWatch Log Group for container logs"
  value = aws_cloudwatch_log_group.main.name
}