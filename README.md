# Scalable Web Service — AWS Infrastructure

## Live Endpoints
- **HTTPS (CloudFront):** https://dfeowc4q7erki.cloudfront.net
- **Health Check:** https://dfeowc4q7erki.cloudfront.net/health
- **Metrics:** https://dfeowc4q7erki.cloudfront.net/metrics

## Architecture Overview
Internet -> CloudFront (HTTPS) -> ALB (HTTP port 80) -> ECS Tasks (port 8080)
- CloudFront handles HTTPS/SSL termination
- ALB distributes traffic across ECS tasks in 2 availability zones
- ECS Fargate runs 2-10 containerized tasks depending on load

## Infrastructure Components

### Networking
- **VPC** with CIDR `10.0.0.0/16`
- **2 public subnets** across `us-east-1a` and `us-east-1b` for high availability
- **Internet Gateway** for public traffic
- **Security Groups**: ALB accepts HTTP from internet; ECS tasks only accept traffic from ALB

### Compute
- **ECS Fargate**: serverless container platform, no EC2 instances to manage
- **Docker Image:** `ghcr.io/therealdwright/scalable-web-service:v1`
- **Task size:** 0.25 vCPU, 512MB memory
- **Minimum tasks:** 2 (one per AZ for failure survival)
- **Maximum tasks:** 10

### Load Balancing
- **Application Load Balancer (ALB)** distributes traffic across ECS tasks
- **Health checks** hit `/health` every 30 seconds
- Unhealthy tasks are automatically replaced

### HTTPS / TLS
- **CloudFront CDN** provides free HTTPS using AWS's default SSL certificate
- All HTTP requests are automatically redirected to HTTPS
- CloudFront forwards requests to the ALB over HTTP internally

> **Note:** A custom domain with ACM + Route 53 was not used due to AWS free tier
> restrictions on domain registration. In production, this would use a custom domain
> with an ACM certificate attached directly to the ALB, removing the need for CloudFront
> solely for TLS termination.

### Auto Scaling
- **ECS Application Auto Scaling** monitors 3 metrics:
  - CPU utilization: scales out at 60%
  - Memory utilization: scales out at 70%
  - ALB request count: scales out at 1000 requests per target
- **Scale out cooldown:** 60 seconds (fast response to traffic spikes)
- **Scale in cooldown:** 300 seconds (conservative scale-down to avoid thrashing)

### Observability
- **CloudWatch Logs**: all container stdout/stderr logged to `/ecs/scalable-web-service` (7 day retention)
- **CloudWatch Dashboard**: `scalable-web-service` dashboard with:
  - ECS CPU Utilization
  - ECS Memory Utilization
  - ECS Running Task Count
  - ALB Request Count
  - ALB Target Response Time
- **Container Insights** enabled on ECS cluster for detailed metrics
- **Prometheus metrics** exposed at `/metrics` endpoint

### IAM (Least Privilege)
- **ECS Execution Role** — only permissions needed to pull the Docker image and write CloudWatch logs
- **ECS Task Role** — only `logs:CreateLogStream` and `logs:PutLogEvents` permissions

## How to Deploy

### Prerequisites
- AWS CLI configured (`aws configure`)
- Terraform >= 1.0 installed

### Deploy
```bash
cd terraform
terraform init
terraform plan
terraform apply
```

### Tear Down
```bash
terraform destroy
```

## Design Decisions & Trade-offs

| Decision | Reason |
|---|---|
| ECS Fargate over EC2 | No server management, scales to zero cost when idle |
| CloudFront for HTTPS | Free SSL without needing a custom domain |
| 2 AZs minimum | Survives single AZ failure |
| Public subnets for tasks | Simpler setup; private subnets + NAT Gateway would add ~$32/month cost |
| 7-day log retention | Balances debuggability with cost |

## What I Would Add in Production
- Custom domain with ACM certificate on the ALB
- Private subnets for ECS tasks with a NAT Gateway
- WAF (Web Application Firewall) on CloudFront
- SNS alerts on CloudWatch alarms for CPU/memory thresholds
- CI/CD pipeline for automated deployments