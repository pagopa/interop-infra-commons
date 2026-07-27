<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.100.0 |
| <a name="requirement_external"></a> [external](#requirement\_external) | ~> 2.3.0 |
| <a name="requirement_local"></a> [local](#requirement\_local) | ~> 2.8.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.100.0 |
| <a name="provider_external"></a> [external](#provider\_external) | ~> 2.3.0 |
| <a name="provider_local"></a> [local](#provider\_local) | ~> 2.8.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_api_gateway_base_path_mapping.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_base_path_mapping) | resource |
| [aws_api_gateway_deployment.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_deployment) | resource |
| [aws_api_gateway_gateway_response.missing_auth_token_404_problem](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_gateway_response) | resource |
| [aws_api_gateway_method_settings.all](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_method_settings) | resource |
| [aws_api_gateway_rest_api.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_rest_api) | resource |
| [aws_api_gateway_stage.env](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_stage) | resource |
| [aws_cloudwatch_dashboard.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_dashboard) | resource |
| [aws_cloudwatch_metric_alarm.apigw_4xx](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.apigw_4xx_low_requests](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.apigw_5xx](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_s3_object.openapi](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object) | resource |
| [aws_wafv2_web_acl_association.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_web_acl_association) | resource |
| [local_file.templated_openapi](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [external_external.openapi_integration](https://registry.terraform.io/providers/hashicorp/external/latest/docs/data-sources/external) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_access_log_group_arn"></a> [access\_log\_group\_arn](#input\_access\_log\_group\_arn) | ARN of the log group where to store APIGW access logs | `string` | `null` | no |
| <a name="input_additional_4xx_alarm_config"></a> [additional\_4xx\_alarm\_config](#input\_additional\_4xx\_alarm\_config) | Additional alarm to catch significant 4xx errors in low-request environment. <br/>    This configuration is an object with the following fields:<br/>     - `period`: the alarm evaluation period in seconds, usually 60.<br/>     - `threshold_percentage`: the `4xx_errors / requests_count` minimum ratio to trigger alarm<br/>     - `min_requests`: the minimum `requests_count`: if the `requests_count` is below <br/>                       `min_requests` the alarm is not set regardless the <br/>                       `4xx_errors / requests_count` ratio<br/>     - `eval_periods`: Number of periods to be evaluated to decide alarm triggering<br/>     - `datapoints`: Number of last N periods are evaluated as 'bad'. Where N is the <br/>                     `eval_periods` value and 'bad' means "A period with at least <br/>                     `min_requests` HTTP request and a `4xx_errors / requests_count` <br/>                     ratio with a value at least `threshold_percentage`".<br/>    If a second alarm do not define this field or define it as `null` | <pre>object({<br/>    threshold_percentage = number<br/>    period               = number<br/>    eval_periods         = number<br/>    datapoints           = number<br/>    min_requests         = number<br/>  })</pre> | `null` | no |
| <a name="input_alarm_4xx_datapoints"></a> [alarm\_4xx\_datapoints](#input\_alarm\_4xx\_datapoints) | Number of breaching datapoints in the evaluation period to trigger the 4xx APIGW alarm | `number` | `0` | no |
| <a name="input_alarm_4xx_eval_periods"></a> [alarm\_4xx\_eval\_periods](#input\_alarm\_4xx\_eval\_periods) | Number of periods to evaluate for the 4xx APIGW alarm | `number` | `0` | no |
| <a name="input_alarm_4xx_min_requests"></a> [alarm\_4xx\_min\_requests](#input\_alarm\_4xx\_min\_requests) | Minimum number of requests to enable 4xx APIGW alarm triggering | `number` | `0` | no |
| <a name="input_alarm_4xx_period"></a> [alarm\_4xx\_period](#input\_alarm\_4xx\_period) | Period (in seconds) over which the 4xx APIGW alarm statistic is applied | `number` | `0` | no |
| <a name="input_alarm_4xx_threshold_percentage"></a> [alarm\_4xx\_threshold\_percentage](#input\_alarm\_4xx\_threshold\_percentage) | Threshold to trigger 4xx APIGW alarm | `number` | `0` | no |
| <a name="input_alarm_5xx_datapoints"></a> [alarm\_5xx\_datapoints](#input\_alarm\_5xx\_datapoints) | Number of breaching datapoints in the evaluation period to trigger the 5xx APIGW alarm | `number` | `0` | no |
| <a name="input_alarm_5xx_eval_periods"></a> [alarm\_5xx\_eval\_periods](#input\_alarm\_5xx\_eval\_periods) | Number of periods to evaluate for the 5xx APIGW alarm | `number` | `0` | no |
| <a name="input_alarm_5xx_period"></a> [alarm\_5xx\_period](#input\_alarm\_5xx\_period) | Period (in seconds) over which the 5xx APIGW alarm statistic is applied | `number` | `0` | no |
| <a name="input_alarm_5xx_threshold"></a> [alarm\_5xx\_threshold](#input\_alarm\_5xx\_threshold) | Threshold to trigger 5xx APIGW alarm | `number` | `0` | no |
| <a name="input_api_name"></a> [api\_name](#input\_api\_name) | Name of the API | `string` | n/a | yes |
| <a name="input_api_version"></a> [api\_version](#input\_api\_version) | (optional) Version of the API exposed by this APIGW | `string` | `null` | no |
| <a name="input_binary_media_types"></a> [binary\_media\_types](#input\_binary\_media\_types) | List of Content-Type values to treat as binary media types | `list(string)` | <pre>[<br/>  "multipart/form-data"<br/>]</pre> | no |
| <a name="input_create_cloudwatch_alarm"></a> [create\_cloudwatch\_alarm](#input\_create\_cloudwatch\_alarm) | If true, a CloudWatch alarm for the 5XXError metric is created for the current API Gateway | `bool` | n/a | yes |
| <a name="input_create_cloudwatch_alarm_4xx"></a> [create\_cloudwatch\_alarm\_4xx](#input\_create\_cloudwatch\_alarm\_4xx) | If true, a CloudWatch alarm for the 4XXError metric is created for the current API Gateway | `bool` | `false` | no |
| <a name="input_create_cloudwatch_dashboard"></a> [create\_cloudwatch\_dashboard](#input\_create\_cloudwatch\_dashboard) | If true, a CloudWatch dashboard is created for the current API Gateway | `bool` | n/a | yes |
| <a name="input_disable_execute_api_endpoint"></a> [disable\_execute\_api\_endpoint](#input\_disable\_execute\_api\_endpoint) | Disable the default endpoint | `bool` | `true` | no |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | Domain name to be assigned to the API Gateway | `string` | `null` | no |
| <a name="input_enable_base_path_mapping"></a> [enable\_base\_path\_mapping](#input\_enable\_base\_path\_mapping) | Enable 'Custom Domain Name' base path mapping | `bool` | `true` | no |
| <a name="input_env"></a> [env](#input\_env) | Environment name | `string` | n/a | yes |
| <a name="input_maintenance_mode"></a> [maintenance\_mode](#input\_maintenance\_mode) | Determines whether the API Gateway is in maintenance mode or not | `bool` | `false` | no |
| <a name="input_maintenance_openapi_path"></a> [maintenance\_openapi\_path](#input\_maintenance\_openapi\_path) | Path to the OpenAPI maintenance file, relative to TF root module (e.g. './openapi/foo/bar.yaml') | `string` | `"./openapi/maintenance/api-maintenance.yaml"` | no |
| <a name="input_openapi_relative_path"></a> [openapi\_relative\_path](#input\_openapi\_relative\_path) | Path to the OpenAPI definition file, relative to TF root module (e.g. './openapi/foo/bar.yaml') | `string` | n/a | yes |
| <a name="input_openapi_s3_bucket_name"></a> [openapi\_s3\_bucket\_name](#input\_openapi\_s3\_bucket\_name) | Name of the S3 bucket to store the OpenAPI definition | `string` | `null` | no |
| <a name="input_openapi_s3_object_key"></a> [openapi\_s3\_object\_key](#input\_openapi\_s3\_object\_key) | Key of the S3 object used to store the OpenAPI definition | `string` | `null` | no |
| <a name="input_remap_missing_auth_token_to_404_problem"></a> [remap\_missing\_auth\_token\_to\_404\_problem](#input\_remap\_missing\_auth\_token\_to\_404\_problem) | Enable remap 403 'Missing Authentication Token' to 404 with the 'Problem' JSON response | `bool` | `false` | no |
| <a name="input_service_prefix"></a> [service\_prefix](#input\_service\_prefix) | Prefix to use when building backend integration URI | `string` | `null` | no |
| <a name="input_sns_topic_arn"></a> [sns\_topic\_arn](#input\_sns\_topic\_arn) | ARN of the SNS topic for alarms notifications | `string` | `null` | no |
| <a name="input_templating_map"></a> [templating\_map](#input\_templating\_map) | Map of strings for OpenAPI templating | `map(string)` | `{}` | no |
| <a name="input_type"></a> [type](#input\_type) | Type of the API. It can be either 'bff' or 'generic' | `string` | n/a | yes |
| <a name="input_vpc_link_id"></a> [vpc\_link\_id](#input\_vpc\_link\_id) | ID of the VPC Link to be used for backend integration | `string` | n/a | yes |
| <a name="input_web_acl_arn"></a> [web\_acl\_arn](#input\_web\_acl\_arn) | ARN of the WAF Web ACL to associate to this APIGW's stage | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_apigw_id"></a> [apigw\_id](#output\_apigw\_id) | ID of the APIGW managed by this module |
| <a name="output_apigw_name"></a> [apigw\_name](#output\_apigw\_name) | Name of the APIGW managed by this module |
| <a name="output_apigw_stage_name"></a> [apigw\_stage\_name](#output\_apigw\_stage\_name) | Name of the stage of the APIGW managed by this module |
<!-- END_TF_DOCS -->