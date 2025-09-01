This module use curl to download a file from an url (`file_url` parameter),
save it in a `destination_path` and check if the sha256 of the file is 
equal to the value given in the `file_sha256_hex` parameter.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.8.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.100.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_external"></a> [external](#provider\_external) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [external_external.curl_wrapper](https://registry.terraform.io/providers/hashicorp/external/latest/docs/data-sources/external) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_destination_path"></a> [destination\_path](#input\_destination\_path) | Path where the file will be downloaded. Exclude "file\_cache\_key" use. | `string` | `null` | no |
| <a name="input_file_cache_key"></a> [file\_cache\_key](#input\_file\_cache\_key) | If specified the module download file into an internal cache. Exclude "destination\_path" use. | `string` | `null` | no |
| <a name="input_file_sha256_hex"></a> [file\_sha256\_hex](#input\_file\_sha256\_hex) | SHA256 of the resource; 64 character: digit, uppercase or lowercase letter from A to F | `string` | n/a | yes |
| <a name="input_file_url"></a> [file\_url](#input\_file\_url) | The url to be downloaded. The module use curl. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_downloaded_file_location"></a> [downloaded\_file\_location](#output\_downloaded\_file\_location) | The same value of "destination\_path" parameter XOR the path to the file cache |
| <a name="output_file_sha256_base64"></a> [file\_sha256\_base64](#output\_file\_sha256\_base64) | n/a |
<!-- END_TF_DOCS -->