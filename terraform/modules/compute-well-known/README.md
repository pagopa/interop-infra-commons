This module read public keys from KMS and generate a JWKS file content

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.8 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.100 |
| <a name="requirement_external"></a> [external](#requirement\_external) | ~> 2.3 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.100 |
| <a name="provider_external"></a> [external](#provider\_external) | ~> 2.3 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_kms_public_key.input](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/kms_public_key) | data source |
| [external_external.kms_to_jwks](https://registry.terraform.io/providers/hashicorp/external/latest/docs/data-sources/external) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_kms_asymmetric_keys_arns"></a> [kms\_asymmetric\_keys\_arns](#input\_kms\_asymmetric\_keys\_arns) | List of kms asymmetric key arns to read the public keys from, to insert into the well\_known file | `list(string)` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_jwks_json_string"></a> [jwks\_json\_string](#output\_jwks\_json\_string) | The computed JWKS in JSON string format |
<!-- END_TF_DOCS -->
