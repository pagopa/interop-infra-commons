locals {
  deploy_argocd           = var.env == "dev"
  argocd_repo_server_name = "argocd-repo-server"
}
