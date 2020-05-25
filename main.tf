provider "aws" {
  region = "us-east-1"
}


resource "aws_ecs_cluster" "cluster" {
  name = "tf-waf-sandbox"

}

resource "aws_ecs_service" "httpbin" {
  name            = "httpbin"
  task_definition = "${aws_ecs_task_definition.httpbin.id}:${aws_ecs_task_definition.httpbin.revision}"
  desired_count   = 1

  cluster = aws_ecs_cluster.cluster.name

  launch_type = "FARGATE"

  network_configuration {
    subnets          = var.httpbin_task_subnets
    security_groups  = [aws_security_group.httpbin_task.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.httpbin.arn
    container_name   = "httpbin"
    container_port   = 8080
  }

  health_check_grace_period_seconds = 100000

  depends_on = [
    aws_iam_role.httpbin_execution,
    aws_alb.httpbin,
    aws_cloudwatch_log_group.httpbin
  ]
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
  name              = "tf-waf-sandbox"
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
resource "aws_security_group" "httpbin_task" {
  name   = "httpbin_task"
  vpc_id = var.vpc_id
}

resource "aws_security_group_rule" "httpbin_task_allow_8080" {
  security_group_id = aws_security_group.httpbin_task.id
  type              = "ingress"
  from_port         = 8080
  to_port           = 8080
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "httpbin_task_allow_icmp" {
  security_group_id = aws_security_group.httpbin_task.id
  type              = "ingress"
  from_port         = -1
  to_port           = -1
  protocol          = "icmp"
  cidr_blocks       = var.admin_cidrs
}

resource "aws_security_group_rule" "httpbin_task_egress" {
  security_group_id = aws_security_group.httpbin_task.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}


resource "aws_security_group" "httpbin_alb" {
  name   = "httpbin_alb"
  vpc_id = var.vpc_id
}

resource "aws_security_group_rule" "httpbin_task_allow_80" {
  security_group_id = aws_security_group.httpbin_alb.id
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "httpbin_alb_egress" {
  security_group_id = aws_security_group.httpbin_alb.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_alb" "httpbin" {

  name = "httpbin"

  subnets = var.httpbin_alb_subnets

  security_groups = [aws_security_group.httpbin_alb.id]
}

resource "aws_alb_listener" "httpbin" {

  default_action {
    target_group_arn = aws_alb_target_group.httpbin.arn
    type             = "forward"
  }

  load_balancer_arn = aws_alb.httpbin.arn
  port              = 80
}

resource "aws_alb_target_group" "httpbin" {
  name                 = "httpbin"
  vpc_id               = var.vpc_id
  port                 = 8080
  protocol             = "HTTP"
  deregistration_delay = 5
  target_type          = "ip"

  health_check {
    healthy_threshold = 2
    interval          = 5
    timeout           = 2
  }
}

