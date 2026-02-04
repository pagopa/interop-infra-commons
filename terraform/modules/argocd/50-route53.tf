locals {
  setup53_architecture = (var.create_argocd_alb &&
    var.deploy_argocd &&
  var.create_private_hosted_zone)
}

data "aws_route53_zone" "public" {
  count = local.setup53_architecture ? 1 : 0

  name         = var.public_hosted_zone_name
  private_zone = false
}

# ACM Certificate for ArgoCD ALB (Amazon issued certificate)
# Validated through DNS in the public hosted zone
resource "aws_acm_certificate" "argocd" {
  count = local.setup53_architecture ? 1 : 0

  domain_name       = format("argocd.%s", data.aws_route53_zone.public[0].name)
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "argocd-cert"
  }
}

# Alias record for ArgoCD ACM DNS validation (used by ACM to issue the certificate)
resource "aws_route53_record" "argocd_cert_validation" {
  
  for_each = local.setup53_architecture ? {
    for dvo in aws_acm_certificate.argocd[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  } : {}

  name    = each.value.name
  records = [each.value.record]
  type    = each.value.type
  zone_id = data.aws_route53_zone.public[0].zone_id
  ttl     = 300
}

# Request a DNS validated certificate, 
# deploy the required validation records and 
# wait for validation to complete.
resource "aws_acm_certificate_validation" "argocd_cert_validation" {
  count = local.setup53_architecture ? 1 : 0

  certificate_arn         = aws_acm_certificate.argocd[0].arn
  validation_record_fqdns = [for record in aws_route53_record.argocd_cert_validation : record.fqdn]
}


###################################
# Private Hosted Zone for ArgoCD. #
###################################
resource "aws_route53_zone" "argocd_private" {
  count = local.setup53_architecture ? 1 : 0

  name = var.public_hosted_zone_name

  # private zone
  vpc {
    vpc_id = data.aws_eks_cluster.this[0].vpc_config[0].vpc_id
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.resource_prefix}-${var.env}-argocd-zone"
    }
  )
}