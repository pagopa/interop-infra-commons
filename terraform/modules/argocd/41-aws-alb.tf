# Only allow inbound HTTPS traffic from VPN clients SG
#resource "aws_security_group" "argocd_alb_sg" {
#  name   = "argocd-alb-internal"
#  vpc_id = data.aws_eks_cluster.this.vpc_config[0].vpc_id
#
#  ingress {
#    from_port   = 443
#    to_port     = 443
#    protocol    = "tcp"
#    cidr_blocks = [data.aws_security_group.vpn_clients.cidr_blocks[0]]
#  }
#
#  egress {
#    from_port   = 0
#    to_port     = 0
#    protocol    = "-1"
#    cidr_blocks = ["0.0.0.0/0"] # TODO
#  }
#}
#
#
## Internal ALB for Argo CD
#resource "aws_lb" "argocd_alb" {
#  name               = format("%s-argocd-internal-alb-%s", var.project, var.env)
#  load_balancer_type = "application"
#  internal           = true
#
#  security_groups = [aws_security_group.argocd_alb_sg.id]
#  subnets         = var.private_subnet_ids
#
#  ip_address_type      = "ipv4"
#  preserve_host_header = true
#
#  #access_logs { # TODO
#  #    
#  #}
#}
#
## Target Group for Argo CD UI and gRPC (http because ArgoCD server is set as insecure in argocd-cm-values.yaml)
#resource "aws_lb_target_group" "argocd_ui_tg" {
#  name             = format("%s-argocd-ui-tg-%s", var.project, var.env)
#  vpc_id           = data.aws_eks_cluster.this.vpc_config[0].vpc_id
#  target_type      = "ip"
#  port             = 80
#  protocol         = "HTTP"
#  protocol_version = "HTTP1"
#
#  health_check {
#    protocol = "HTTP"
#    path     = "/healthz"  # TODO
#    matcher  = "200"
#  }
#}
#
#resource "aws_lb_target_group" "argocd_grpc_tg" {
#  name             = format("%s-argocd-grpc-tg-%s", var.project, var.env)
#  vpc_id           = data.aws_eks_cluster.this.vpc_config[0].vpc_id
#  target_type      = "ip"
#  port             = 80
#  protocol         = "HTTP"
#  protocol_version = "HTTP2"
#
#  health_check {
#    protocol = "HTTP"
#    path     = "/healthz" # TODO
#    matcher  = "200"
#  }
#}

# When using an ALB, you'll want to create a second service for argocd-server.
# This is necessary because we need to tell the ALB to send the GRPC traffic 
# to a different target group than the UI traffic, 
# since the backend protocol is HTTP2 instead of HTTP1.
# https://argo-cd.readthedocs.io/en/stable/operator-manual/ingress/#aws-application-load-balancers-albs-and-classic-elb-http-mode

# HTTPS Listener for ALB
#resource "aws_lb_listener" "https_443" {
#  load_balancer_arn = aws_lb.argocd_alb.arn
#  port              = 443
#  protocol          = "HTTPS"
#  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
#  certificate_arn   = var.acm_cert_arn # TODO
#
#  default_action {
#    type             = "forward"
#    target_group_arn = aws_lb_target_group.argocd_ui_tg.arn
#  }
#}
#
## Listener Rule to forward gRPC traffic to the gRPC target group
#resource "aws_lb_listener_rule" "grpc_header_rule" {
#  listener_arn = aws_lb_listener.https_443.arn
#  priority     = 10
#
#  action {
#    type             = "forward"
#    target_group_arn = aws_lb_target_group.argocd_grpc_tg.arn
#  }
#
#  condition {
#    http_header {
#      http_header_name = "Content-Type"
#      values           = ["application/grpc*"]
#    }
#  }
#}
