provider "aws" {
  region = "us-east-1"
}


resource "aws_ecs_cluster" "cluster" {
  name = "tf-waf-sandbox"

}

resource "aws_ecs_service" "httpbin" {
  name = "httpbin"
  task_definition = aws_ecs_task_definition.httpbin.id
  desired_count = 1

  cluster = aws_ecs_cluster.cluster.name

  launch_type = "FARGATE"

  network_configuration {
    subnets = var.httpbin_subnets
    security_groups = [aws_security_group.httpbin.id]
    assign_public_ip = true
  }
}

resource "aws_ecs_task_definition" "httpbin" {
  family = "httpbin"
  container_definitions = file("templates/httpbin.json")
  requires_compatibilities = ["FARGATE"]

  cpu = 256
  memory       = 512
  network_mode = "awsvpc"
}

resource "aws_security_group" "httpbin" {
  name = "httpbin"
  vpc_id = var.vpc_id
}


resource "aws_security_group_rule" "httpbin_allow_22" {
  security_group_id = aws_security_group.httpbin.id
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = var.admin_cidrs
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

