resource "aws_wafv2_web_acl" "httpbin" {
  name = "tf_waf_sandbox"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = false
    metric_name = "tf_waf_sandbox"
    sampled_requests_enabled = true
  }

  rule {
    name     = "AWS-AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      count {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "friendly-rule-metric-name"
      sampled_requests_enabled   = true
    }
  }

  tags = {
    Tag1 = "Value1"
    Tag2 = "Value2"
  }


}

resource "aws_wafv2_web_acl_association" "httpbin" {
  resource_arn = aws_alb.httpbin.arn
  web_acl_arn = aws_wafv2_web_acl.httpbin.arn
}
