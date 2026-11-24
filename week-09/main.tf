provider "aws" { region = "us-east-1" }

data "aws_caller_identity" "current" {}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.8.1"

  name = "training-vpc-tf"
  cidr = "10.1.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  public_subnets  = ["10.1.1.0/24", "10.1.2.0/24"]
  private_subnets = ["10.1.101.0/24", "10.1.102.0/24"]

  # The task runs in a public subnet with a public IP, so no NAT is needed this week
  enable_nat_gateway = false
}

resource "aws_ecs_cluster" "training" {
  name = "training-cluster"
}

resource "aws_iam_role" "ecs_execution" {
  name = "ecs-task-execution-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_cloudwatch_log_group" "property_api" {
  name              = "/ecs/property-api"
  retention_in_days = 1
}

resource "aws_security_group" "property_api" {
  name   = "property-api-sg"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ecs_task_definition" "property_api" {
  family                   = "property-api"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_execution.arn

  container_definitions = jsonencode([{
    name         = "property-api"
    image        = "${data.aws_caller_identity.current.account_id}.dkr.ecr.us-east-1.amazonaws.com/property-api:latest"
    essential    = true
    portMappings = [{ containerPort = 8080, hostPort = 8080 }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.property_api.name
        "awslogs-region"        = "us-east-1"
        "awslogs-stream-prefix" = "property-api"
      }
    }
  }])
}

resource "aws_ecs_service" "property_api" {
  name            = "property-api-service"
  cluster         = aws_ecs_cluster.training.id
  task_definition = aws_ecs_task_definition.property_api.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = module.vpc.public_subnets
    security_groups  = [aws_security_group.property_api.id]
    assign_public_ip = true
  }
}
