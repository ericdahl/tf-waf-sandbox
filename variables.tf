variable "admin_cidrs" {
  type    = list(string)
  default = []
}

variable "vpc_id" {
  type = string
}

variable "httpbin_task_subnets" {
  type = list(string)
}

variable "httpbin_alb_subnets" {
  type = list(string)
}
