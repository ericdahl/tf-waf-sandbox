variable "admin_cidrs" {
  type    = list(string)
  default = []
}

variable "vpc_id" {
  type = string
}

variable "httpbin_subnets" {
  type = list(string)
}
