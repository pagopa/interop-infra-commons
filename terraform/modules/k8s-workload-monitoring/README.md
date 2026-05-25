<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.8.0, < 2.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.46 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 5.46 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_dashboard.k8s_deployment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_dashboard) | resource |
| [aws_cloudwatch_metric_alarm.app_errors](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.avg_cpu](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.avg_memory](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.readiness_pods](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.unavailable_pods](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_alarm_datapoints"></a> [alarm\_datapoints](#input\_alarm\_datapoints) | Number of breaching datapoints in the evaluation period to trigger the alarms | `number` | `1` | no |
| <a name="input_alarm_eval_periods"></a> [alarm\_eval\_periods](#input\_alarm\_eval\_periods) | Number of periods to evaluate for the alarms | `number` | `1` | no |
| <a name="input_avg_cpu_alarm_threshold"></a> [avg\_cpu\_alarm\_threshold](#input\_avg\_cpu\_alarm\_threshold) | Threshold to trigger the AVG cpu alarm | `number` | `60` | no |
| <a name="input_avg_memory_alarm_threshold"></a> [avg\_memory\_alarm\_threshold](#input\_avg\_memory\_alarm\_threshold) | Threshold to trigger the AVG memory alarm | `number` | `60` | no |
| <a name="input_cloudwatch_app_logs_errors_metric_name"></a> [cloudwatch\_app\_logs\_errors\_metric\_name](#input\_cloudwatch\_app\_logs\_errors\_metric\_name) | Name of the app logs metric in CloudWatch | `string` | `null` | no |
| <a name="input_cloudwatch_app_logs_errors_metric_namespace"></a> [cloudwatch\_app\_logs\_errors\_metric\_namespace](#input\_cloudwatch\_app\_logs\_errors\_metric\_namespace) | Namespace of the app logs metric in CloudWatch | `string` | `null` | no |
| <a name="input_create_app_logs_errors_alarm"></a> [create\_app\_logs\_errors\_alarm](#input\_create\_app\_logs\_errors\_alarm) | If set to true, creates the app\_errors alarms | `bool` | n/a | yes |
| <a name="input_create_dashboard"></a> [create\_dashboard](#input\_create\_dashboard) | If set to true, creates the dashboard | `bool` | n/a | yes |
| <a name="input_create_performance_alarm"></a> [create\_performance\_alarm](#input\_create\_performance\_alarm) | If set to true, creates the avg\_cpu and avg\_memory alarms | `bool` | n/a | yes |
| <a name="input_create_pod_availability_alarm"></a> [create\_pod\_availability\_alarm](#input\_create\_pod\_availability\_alarm) | If set to true, creates the unavailable\_pods alarm | `bool` | n/a | yes |
| <a name="input_create_pod_readiness_alarm"></a> [create\_pod\_readiness\_alarm](#input\_create\_pod\_readiness\_alarm) | If set to true, creates the readiness\_pods alarm | `bool` | n/a | yes |
| <a name="input_eks_cluster_name"></a> [eks\_cluster\_name](#input\_eks\_cluster\_name) | Name of the EKS cluster | `string` | n/a | yes |
| <a name="input_k8s_namespace"></a> [k8s\_namespace](#input\_k8s\_namespace) | Namespace of the K8s deployment | `string` | n/a | yes |
| <a name="input_k8s_workload_name"></a> [k8s\_workload\_name](#input\_k8s\_workload\_name) | Name of the K8s workload | `string` | n/a | yes |
| <a name="input_kind"></a> [kind](#input\_kind) | Kubernetes workload type | `string` | n/a | yes |
| <a name="input_number_of_digits"></a> [number\_of\_digits](#input\_number\_of\_digits) | Number of digits after the comma | `number` | `0` | no |
| <a name="input_performance_alarms_period_seconds"></a> [performance\_alarms\_period\_seconds](#input\_performance\_alarms\_period\_seconds) | Period (in seconds) over which the alarm statistic is applied for performance alarms | `number` | `null` | no |
| <a name="input_sns_topics_arns"></a> [sns\_topics\_arns](#input\_sns\_topics\_arns) | ARNs of the SNS topics for alarms notifications | `list(string)` | `[]` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to the resources created by this module | `map(any)` | <pre>{<br/>  "CreatedBy": "Terraform"<br/>}</pre> | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->