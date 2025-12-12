resource "aws_api_gateway_domain_name" "this" {
  domain_name              = var.domain_name
  regional_certificate_arn = aws_acm_certificate_validation.this.certificate_arn

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_route53_record" "alias_a" {
  name            = aws_api_gateway_domain_name.this.domain_name
  type            = "A"
  zone_id         = var.hosted_zone_id
  allow_overwrite = true

  alias {
    evaluate_target_health = true
    name                   = aws_api_gateway_domain_name.this.regional_domain_name
    zone_id                = aws_api_gateway_domain_name.this.regional_zone_id
  }
}

resource "aws_route53_record" "alias_aaaa" {
  name            = aws_api_gateway_domain_name.this.domain_name
  type            = "AAAA"
  zone_id         = var.hosted_zone_id
  allow_overwrite = true

  alias {
    evaluate_target_health = true
    name                   = aws_api_gateway_domain_name.this.regional_domain_name
    zone_id                = aws_api_gateway_domain_name.this.regional_zone_id
  }
}

