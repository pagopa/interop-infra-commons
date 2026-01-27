# Base Hosted Zone for ArgoCD
resource "aws_route53_zone" "argocd_private" {
  count = var.enable_argocd_alb && var.deploy_argocd && var.create_private_hosted_zone && var.argocd_domain != null ? 1 : 0

  name = var.argocd_hosted_zone_name

  vpc {
    vpc_id = data.aws_eks_cluster.this.vpc_config[0].vpc_id
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project}-${var.env}-argocd-zone"
    }
  )
}

# ACM Certificate for ArgoCD ALB
resource "aws_acm_certificate" "argocd_server" {
  domain_name       = format("argocd.%s", aws_route53_zone.argocd_private.name)
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# Alias record for ArgoCD ALB
resource "aws_route53_record" "argocd" {
  count = var.create_route53_record ? 1 : 0

  zone_id = aws_route53_zone.argocd_private[0].zone_id
  name    = var.argocd_domain
  type    = "A"

  alias {
    name                   = aws_lb.argocd[0].dns_name
    zone_id                = aws_lb.argocd[0].zone_id
    evaluate_target_health = true
  }
}
