variable "kms_asymmetric_keys_arns" {
  description = "List of kms asymmetric key arns to read the public keys from, to insert into the well_known file"
  type        = list(string)
}
