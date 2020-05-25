resource "aws_wafregional_ipset" "httpbin" {
  name = "httpbin"

  ip_set_descriptor {
    type  = "IPV4"
    value = "192.0.7.0/24"
  }
}

resource "aws_wafregional_rule" "httpbin" {
  name        = "httpbin"
  metric_name = "httpbin"

  predicate {
    data_id = aws_wafregional_ipset.httpbin.id
    negated = false
    type    = "IPMatch"
  }
}

resource "aws_wafregional_web_acl" "httpbin" {
  name        = "httpbin"
  metric_name = "httpbin"

  default_action {
    type = "ALLOW"
  }

  rule {
    action {
      type = "BLOCK"
    }

    priority = 1
    rule_id  = aws_wafregional_rule.httpbin.id
    type     = "REGULAR"
  }
}


resource "aws_wafregional_web_acl_association" "httpbin" {
  resource_arn = aws_alb.httpbin.arn
  web_acl_id = aws_wafregional_web_acl.httpbin.id
}

