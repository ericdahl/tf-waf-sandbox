provider "aws" {
  region = "us-east-1"
}


resource "aws_ecs_cluster" "cluster" {
  name = "tf-waf-sandbox"

}

resource "aws_ecs_service" "httpbin" {
  name            = "httpbin"
  task_definition = aws_ecs_task_definition.httpbin.id
  desired_count   = 1

  cluster = aws_ecs_cluster.cluster.name

  launch_type = "FARGATE"

  network_configuration {
    subnets          = var.httpbin_subnets
    security_groups  = [aws_security_group.httpbin.id]
    assign_public_ip = true
  }
}

resource "aws_ecs_task_definition" "httpbin" {
  family                   = "httpbin"
  container_definitions    = file("templates/httpbin.json")
  requires_compatibilities = ["FARGATE"]

  cpu          = 256
  memory       = 512
  network_mode = "awsvpc"

  execution_role_arn = aws_iam_role.httpbin_execution.arn
}

resource "aws_cloudwatch_log_group" "httpbin" {
  name = "tf-waf-sandbox"
  retention_in_days = 7
}


resource "aws_iam_role" "httpbin_execution" {
  name = "httpbin_execution"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com",

        "Service": "ecs.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

}

resource "aws_iam_policy" "httpbin_execution" {
  name   = "httpbin_execution"
  policy = data.aws_iam_policy_document.httpbin_execution.json
}

data "aws_iam_policy_document" "httpbin_execution" {
  statement {
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy_attachment" "httpbin_execution" {
  policy_arn = aws_iam_policy.httpbin_execution.arn
  role       = aws_iam_role.httpbin_execution.name
}
resource "aws_security_group" "httpbin" {
  name   = "httpbin"
  vpc_id = var.vpc_id
}


resource "aws_security_group_rule" "httpbin_allow_22" {
  security_group_id = aws_security_group.httpbin.id
  type              = "ingress"
  from_port         = 8080
  to_port           = 8080
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "httpbin_allow_icmp" {
  security_group_id = aws_security_group.httpbin.id
  type              = "ingress"
  from_port         = -1
  to_port           = -1
  protocol          = "icmp"
  cidr_blocks       = var.admin_cidrs
}

resource "aws_security_group_rule" "httpbin_egress" {
  security_group_id = aws_security_group.httpbin.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

