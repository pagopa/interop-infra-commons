data "aws_kms_public_key" "input" {
  count = length(var.kms_asymmetric_keys_arns)

  key_id = var.kms_asymmetric_keys_arns[count.index]
}

locals {
  public_keys = [for pub_key in data.aws_kms_public_key.input :
    {
      PublicKey         = pub_key.public_key
      KeyId             = pub_key.arn
      SigningAlgorithms = pub_key.signing_algorithms
    }
  ]
}

data "external" "kms_to_jwks" {
  program = ["bash", "${path.module}/scripts/kms-to-jwks.sh"]

  query = {
    public_keys = jsonencode(local.public_keys)
  }
}
