<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.8.0, < 2.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.46 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.46.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_dashboard.apigw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_dashboard) | resource |
| [aws_cloudwatch_dashboard.single_endpoint](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_dashboard) | resource |
| [aws_cloudwatch_metric_alarm.sla_endpoint_error_rate](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.sla_endpoint_p90_response_time](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.sla_endpoint_request_count](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.sla_error_rate](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.sla_p90_response_time](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.sla_request_count](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_alarm_actions"></a> [alarm\_actions](#input\_alarm\_actions) | List of ARNs to notify when alarm enters ALARM state | `list(string)` | `null` | no |
| <a name="input_alarm_evaluation_periods"></a> [alarm\_evaluation\_periods](#input\_alarm\_evaluation\_periods) | The number of periods over which data is compared to the specified threshold | `number` | `2` | no |
| <a name="input_api_stage"></a> [api\_stage](#input\_api\_stage) | The stage of the API Gateway | `string` | n/a | yes |
| <a name="input_apigw_name"></a> [apigw\_name](#input\_apigw\_name) | Name of the API Gateway | `string` | n/a | yes |
| <a name="input_apigw_single_endpoint_name"></a> [apigw\_single\_endpoint\_name](#input\_apigw\_single\_endpoint\_name) | Name of the API Gateway | `string` | n/a | yes |
| <a name="input_dashboard_prefix"></a> [dashboard\_prefix](#input\_dashboard\_prefix) | Prefix for the CloudWatch dashboard names | `string` | n/a | yes |
| <a name="input_env"></a> [env](#input\_env) | Environment name | `string` | n/a | yes |
| <a name="input_error_rate_threshold"></a> [error\_rate\_threshold](#input\_error\_rate\_threshold) | The maximum allowed error rate percentage | `number` | n/a | yes |
| <a name="input_latency_threshold"></a> [latency\_threshold](#input\_latency\_threshold) | The maximum allowed P90 latency in seconds | `number` | n/a | yes |
| <a name="input_minimum_requests_threshold"></a> [minimum\_requests\_threshold](#input\_minimum\_requests\_threshold) | The minimum number of requests expected in a 2-hour period | `number` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_alarm_actions"></a> [alarm\_actions](#output\_alarm\_actions) | The list of ARNs to notify when an alarm enters the ALARM state |
| <a name="output_alarm_evaluation_periods"></a> [alarm\_evaluation\_periods](#output\_alarm\_evaluation\_periods) | The number of periods over which data is compared to the specified threshold for alarms |
| <a name="output_alarm_names"></a> [alarm\_names](#output\_alarm\_names) | The names of the CloudWatch alarms |
| <a name="output_api_gateway_name"></a> [api\_gateway\_name](#output\_api\_gateway\_name) | The name of the API Gateway |
| <a name="output_api_gateway_single_endpoint_name"></a> [api\_gateway\_single\_endpoint\_name](#output\_api\_gateway\_single\_endpoint\_name) | The name of the API Gateway single endpoint |
| <a name="output_api_gateway_stage"></a> [api\_gateway\_stage](#output\_api\_gateway\_stage) | The stage of the API Gateway |
| <a name="output_aws_account_id"></a> [aws\_account\_id](#output\_aws\_account\_id) | The AWS account ID where the resources are deployed |
| <a name="output_aws_region"></a> [aws\_region](#output\_aws\_region) | The AWS region where the resources are deployed |
| <a name="output_dashboard_names"></a> [dashboard\_names](#output\_dashboard\_names) | The names of the CloudWatch dashboards |
| <a name="output_environment"></a> [environment](#output\_environment) | The environment where the resources are deployed |
| <a name="output_error_rate_threshold"></a> [error\_rate\_threshold](#output\_error\_rate\_threshold) | The maximum allowed error rate percentage for alarms |
| <a name="output_latency_threshold"></a> [latency\_threshold](#output\_latency\_threshold) | The maximum allowed P90 latency in seconds for alarms |
| <a name="output_minimum_requests_threshold"></a> [minimum\_requests\_threshold](#output\_minimum\_requests\_threshold) | The minimum number of requests expected in a 2-hour period for alarms |
<!-- END_TF_DOCS -->