locals {
    setup_loadbalancer = var.create_argocd_alb && var.deploy_argocd
}


resource "aws_security_group" "argocd_alb_sg" {
  count = local.setup_loadbalancer ? 1 : 0

  name        = format("alb/%s-argocd-%s", var.resource_prefix, var.env)
  description = "Allow HTTPS from VPN or internal CIDR"
  vpc_id      = data.aws_eks_cluster.this[0].vpc_config[0].vpc_id

  tags = {
    Name = format("alb/%s-argocd-%s", var.resource_prefix, var.env)
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_https_from_vpc" {
  count = local.setup_loadbalancer ? 1 : 0

  security_group_id = aws_security_group.argocd_alb_sg[0].id
  referenced_security_group_id = data.aws_security_group.vpn_clients[0].id
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  count = local.setup_loadbalancer ? 1 : 0

  security_group_id = aws_security_group.argocd_alb_sg[0].id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # all protocols
}


# Internal Application Load Balancer for ArgoCD.
resource "aws_lb" "argocd" {
  count = local.setup_loadbalancer ? 1 : 0

  name                       = format("%s-argocd-alb-%s", var.resource_prefix, var.env)
  enable_deletion_protection = var.env == "prod" ? true : false
  internal                   = true
  load_balancer_type         = "application"
  preserve_host_header       = true
  ip_address_type            = "ipv4"
  enable_http2               = true
  idle_timeout               = 300

  subnets         = var.private_subnet_ids
  security_groups = [aws_security_group.argocd_alb_sg[0].id]

  tags = {
    Name        = format("%s-argocd-alb-%s", var.resource_prefix, var.env)
    Environment = var.env
    Project     = var.resource_prefix
  }
}

# Alias record for ArgoCD ALB
resource "aws_route53_record" "argocd_alb_alias" {
  count = local.setup_loadbalancer ? 1 : 0

  name    = "${var.argocd_subdomain}.${var.public_hosted_zone_name}"
  zone_id = aws_route53_zone.argocd_private[0].zone_id
  type    = "A"

  alias {
    name                   = aws_lb.argocd[0].dns_name
    zone_id                = aws_lb.argocd[0].zone_id
    evaluate_target_health = true
  }

}