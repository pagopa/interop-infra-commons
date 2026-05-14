<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.8.0, < 2.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.100.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 5.100.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_metric_alarm.bounce](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.complaint](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.reject](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_route53_record.dkim](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.mx](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.spf](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_sesv2_configuration_set.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sesv2_configuration_set) | resource |
| [aws_sesv2_configuration_set_event_destination.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sesv2_configuration_set_event_destination) | resource |
| [aws_sesv2_email_identity.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sesv2_email_identity) | resource |
| [aws_sesv2_email_identity_mail_from_attributes.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sesv2_email_identity_mail_from_attributes) | resource |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_create_alarms"></a> [create\_alarms](#input\_create\_alarms) | If true, CloudWatch alarms are created for Reject, Bounce and Complaint metrics | `bool` | n/a | yes |
| <a name="input_hosted_zone_id"></a> [hosted\_zone\_id](#input\_hosted\_zone\_id) | ID of the hosted zone in which records will be created for DKIM and SPF authentication purposes | `string` | n/a | yes |
| <a name="input_ses_identity_name"></a> [ses\_identity\_name](#input\_ses\_identity\_name) | Name of the SES Identity to create. It can be either an email address or a domain | `string` | n/a | yes |
| <a name="input_ses_reputation_sns_topics_arn"></a> [ses\_reputation\_sns\_topics\_arn](#input\_ses\_reputation\_sns\_topics\_arn) | List of SNS topic ARNs in which CloudWatch will publish a message when the Reputation Alarms (Bounce and Complaint) are triggered. It must not be null if create\_alarms is true. | `list(string)` | `null` | no |
| <a name="input_sns_topics_arn"></a> [sns\_topics\_arn](#input\_sns\_topics\_arn) | List of SNS topic ARNs in which CloudWatch will publish a message when the Reject Alarm is triggered. It must not be null if create\_alarms is true. | `list(string)` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_ses_configuration_set_arn"></a> [ses\_configuration\_set\_arn](#output\_ses\_configuration\_set\_arn) | ARN of the Configuration Set managed by this module |
| <a name="output_ses_configuration_set_name"></a> [ses\_configuration\_set\_name](#output\_ses\_configuration\_set\_name) | Name of the Configuration Set managed by this module |
| <a name="output_ses_identity_arn"></a> [ses\_identity\_arn](#output\_ses\_identity\_arn) | ARN of the SES Identity managed by this module |
| <a name="output_ses_identity_name"></a> [ses\_identity\_name](#output\_ses\_identity\_name) | Name of the SES Identity managed by this module |
<!-- END_TF_DOCS -->