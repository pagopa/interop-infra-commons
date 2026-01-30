# Target Group for UI (HTTP1 with session stickiness)
resource "aws_lb_target_group" "argocd_ui" {
  count = local.setup_loadbalancer ? 1 : 0
  
  name  = substr(format("%s-argocd-ui-%s", var.project, var.env), 0, 32)

  port                 = 80
  protocol             = "HTTP"
  protocol_version     = "HTTP1"
  target_type          = "ip"
  ip_address_type      = "ipv4"
  deregistration_delay = 30
  vpc_id               = data.aws_eks_cluster.this.vpc_config[0].vpc_id

  stickiness {
    enabled         = true
    type            = "lb_cookie"
    cookie_duration = 3600 # 1 hour
  }

  health_check {
    enabled             = true
    protocol            = "HTTP"
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
    matcher             = "200-399"
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name        = format("%s-argocd-ui-%s", var.project, var.env)
    Environment = var.env
    Project     = var.project
  }
}

# Target Group for gRPC (HTTP2)
resource "aws_lb_target_group" "argocd_grpc" {
  count = local.setup_loadbalancer ? 1 : 0

  name                 = substr(format("%s-argocd-grpc-%s", var.project, var.env), 0, 32)
  vpc_id               = data.aws_eks_cluster.this.vpc_config[0].vpc_id
  target_type          = "ip"
  port                 = 80
  protocol             = "HTTP"
  protocol_version     = "HTTP2"
  deregistration_delay = 30

  stickiness {
    enabled         = true
    type            = "lb_cookie"
    cookie_duration = 3600 # 1 hour
  }
  health_check {
    enabled             = true
    protocol            = "HTTP"
    path                = "/grpc.health.v1.Health/Check"
    matcher             = "0"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name        = format("%s-argocd-grpc-%s", var.project, var.env)
    Environment = var.env
    Project     = var.project
  }
}


# When using an ALB, you'll want to create a second service for argocd-server.
# This is necessary because we need to tell the ALB to send the GRPC traffic 
# to a different target group than the UI traffic, 
# since the backend protocol is HTTP2 instead of HTTP1.
# https://argo-cd.readthedocs.io/en/stable/operator-manual/ingress/#aws-application-load-balancers-albs-and-classic-elb-http-mode

# HTTPS Listener for ALB
resource "aws_lb_listener" "argocd_https" {
  count = local.setup_loadbalancer ? 1 : 0

  load_balancer_arn = aws_lb.argocd[0].arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate_validation.argocd_cert_validation[0].certificate_arn


  # Default action: forward to UI target group
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.argocd_ui[0].arn
  }

  tags = var.tags
}

# Listener Rule for gRPC
# Forward gRPC traffic (Content-Type: application/grpc*) to gRPC target group
resource "aws_lb_listener_rule" "grpc_header_rule" {
  count = local.setup_loadbalancer ? 1 : 0

  listener_arn = aws_lb_listener.argocd_https[0].arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.argocd_grpc[0].arn
  }

  condition {
    http_header {
      http_header_name = "Content-Type"
      values           = ["application/grpc"]
    }
  }
}

# Target Group Binding for ui service
resource "kubernetes_manifest" "argocd_ui_tgb" {
  count = local.setup_loadbalancer ? 1 : 0

  depends_on = [
    helm_release.argocd,
    aws_lb_target_group.argocd_ui[0]
  ]
  
  manifest = {
    apiVersion = "elbv2.k8s.aws/v1beta1"
    kind       = "TargetGroupBinding"
    metadata = {
      name      = "argocd-server-ui"
      namespace = var.argocd_namespace

    }
    spec = {
      serviceRef = {
        name = "argocd-server"
        port = 80
      }
      targetGroupARN = aws_lb_target_group.argocd_ui[0].arn
    }
  }
}

# Target Group Binding for grpc service
resource "kubernetes_manifest" "argocd_grpc_tgb" {
  count = local.setup_loadbalancer ? 1 : 0

  depends_on = [
    kubernetes_service_v1.argogrpc,
    aws_lb_target_group.argocd_grpc
  ]

  manifest = {
    apiVersion = "elbv2.k8s.aws/v1beta1"
    kind       = "TargetGroupBinding"
    metadata = {
      name      = "argocd-server-grpc"
      namespace = var.argocd_namespace
    }
    spec = {
      serviceRef = {
        name = kubernetes_service_v1.argogrpc.metadata[0].name
        port = 80
      }
      targetGroupARN = aws_lb_target_group.argocd_grpc[0].arn
    }
  }
}
