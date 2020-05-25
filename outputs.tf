output "aws_alb_httpbin_url" {
  value = "http://${aws_alb.httpbin.dns_name}"
}
