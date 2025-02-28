# TODO: make time periods configurable

resource "aws_cloudwatch_dashboard" "k8s_deployment" {
  count = var.create_dashboard ? 1 : 0 
  dashboard_name = format("k8s-%s-%s", var.k8s_workload_name, var.k8s_namespace)
  dashboard_body = templatefile("${path.module}/k8s_deployment_dashboard.tpl.json",
    {
      Region                   = data.aws_region.current.name
      ClusterName              = var.eks_cluster_name
      Namespace                = var.k8s_namespace
      Service                  = var.k8s_workload_name
      ServiceType              = lower(var.kind)
      NumberOfDigitsMultiplier = pow(10, var.number_of_digits)
    }
  )
}
