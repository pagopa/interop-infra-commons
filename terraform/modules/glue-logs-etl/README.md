<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.8.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.46.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.6.3 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 5.46.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_glue_job.glue_job](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/glue_job) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_glue_database_name"></a> [glue\_database\_name](#input\_glue\_database\_name) | Name of the Glue database | `string` | n/a | yes |
| <a name="input_glue_job_command_script"></a> [glue\_job\_command\_script](#input\_glue\_job\_command\_script) | Path to the Glue job script | `string` | n/a | yes |
| <a name="input_glue_job_concurrency"></a> [glue\_job\_concurrency](#input\_glue\_job\_concurrency) | Max concurrent runs of the Glue job | `number` | `1` | no |
| <a name="input_glue_job_enable_auto_scaling"></a> [glue\_job\_enable\_auto\_scaling](#input\_glue\_job\_enable\_auto\_scaling) | Enable auto scaling of the Glue job | `bool` | `false` | no |
| <a name="input_glue_job_max_capacity"></a> [glue\_job\_max\_capacity](#input\_glue\_job\_max\_capacity) | Max capacity of the Glue job | `number` | n/a | yes |
| <a name="input_glue_job_max_retries"></a> [glue\_job\_max\_retries](#input\_glue\_job\_max\_retries) | Max retries of the Glue job | `number` | `0` | no |
| <a name="input_glue_job_name"></a> [glue\_job\_name](#input\_glue\_job\_name) | Name of the Glue job | `string` | n/a | yes |
| <a name="input_glue_job_number_of_workers"></a> [glue\_job\_number\_of\_workers](#input\_glue\_job\_number\_of\_workers) | Number of Glue workers | `number` | `1` | no |
| <a name="input_glue_job_role_arn"></a> [glue\_job\_role\_arn](#input\_glue\_job\_role\_arn) | ARN of the IAM role for the Glue job | `string` | n/a | yes |
| <a name="input_glue_job_security_configuration"></a> [glue\_job\_security\_configuration](#input\_glue\_job\_security\_configuration) | Name of the Glue security configuration | `string` | `null` | no |
| <a name="input_glue_job_tags"></a> [glue\_job\_tags](#input\_glue\_job\_tags) | List of Glue job tags | `map(string)` | `{}` | no |
| <a name="input_glue_job_timeout"></a> [glue\_job\_timeout](#input\_glue\_job\_timeout) | Timeout of the Glue job | `number` | n/a | yes |
| <a name="input_glue_job_timeout_minutes"></a> [glue\_job\_timeout\_minutes](#input\_glue\_job\_timeout\_minutes) | Timeout of the Glue job (default 48 hours) | `number` | `2880` | no |
| <a name="input_glue_job_version"></a> [glue\_job\_version](#input\_glue\_job\_version) | Version of Glue | `string` | `"4.0"` | no |
| <a name="input_glue_job_worker_type"></a> [glue\_job\_worker\_type](#input\_glue\_job\_worker\_type) | Type of Glue worker | `string` | `"G.1X"` | no |
| <a name="input_glue_table_name"></a> [glue\_table\_name](#input\_glue\_table\_name) | Name of the Glue table | `string` | n/a | yes |
| <a name="input_s3_destination_bucket"></a> [s3\_destination\_bucket](#input\_s3\_destination\_bucket) | S3 destination bucket | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_secret_arn"></a> [secret\_arn](#output\_secret\_arn) | User credentials secret ARN |
| <a name="output_secret_id"></a> [secret\_id](#output\_secret\_id) | User credentials secret ID |

### Usage example - TBD

```
module "sql_roles" {
  source       = "./modules/glue-logs-etl"
  
}
```
<!-- END_TF_DOCS -->