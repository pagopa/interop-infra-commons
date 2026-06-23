data "aws_kms_public_key" "well_known_keys" {
  count = length(var.kms_asymmetric_keys_arns)

  key_id = var.kms_asymmetric_keys_arns[count.index]
}

locals {
  public_keys = [for pub_key in data.aws_kms_public_key.well_known_keys :
    {
      PublicKey         = pub_key.public_key
      KeyId             = pub_key.arn
      SigningAlgorithms = pub_key.signing_algorithms
    }
  ]
}

data "external" "well_known_body_generation" {
  program = ["bash", "${path.module}/scripts/kms-to-jwks.sh"]

  query = {
    public_keys = jsonencode(local.public_keys)
  }
}
