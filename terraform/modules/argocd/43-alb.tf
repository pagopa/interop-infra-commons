locals {
    setup_loadbalancer = var.create_argocd_alb && var.deploy_argocd
}

resource "aws_security_group" "argocd_alb_sg" {
  name        = format("alb/%s-argocd-%s", var.project, var.env)
  description = "Allow HTTPS from VPN or internal CIDR"
  vpc_id      = data.aws_eks_cluster.this.vpc_config[0].vpc_id

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [data.aws_security_group.vpn_clients.cidr_blocks[0]] # TODO
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = format("alb/%s-argocd-%s", var.project, var.env)
  }
}

# Internal Application Load Balancer for ArgoCD.
resource "aws_lb" "argocd" {
  count = local.setup_loadbalancer ? 1 : 0

  name                       = format("%s-argocd-alb-%s", var.project, var.env)
  enable_deletion_protection = var.env == "prod" ? true : false
  internal                   = true
  load_balancer_type         = "application"
  preserve_host_header       = true
  ip_address_type            = "ipv4"
  enable_http2               = true
  idle_timeout               = 300

  subnets         = var.private_subnet_ids
  security_groups = [aws_security_group.argocd_alb_sg.id]

  tags = {
    Name        = format("%s-argocd-alb-%s", var.project, var.env)
    Environment = var.env
    Project     = var.project
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