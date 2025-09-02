
locals {
  full_destination_path = (
    var.destination_path != null
    ? trimspace(var.destination_path)
    : format("%s/file_cache/%s", path.module, trimspace(var.file_cache_key))
  )
}

data "external" "curl_wrapper" {

  program = ["bash", "${path.module}/scripts/download_and_check_file.sh"]

  query = {
    url              = var.file_url
    hex_sha256       = var.file_sha256_hex
    destination_path = local.full_destination_path
  }

  lifecycle {

    precondition {

      # - This condition checks that exactly one of the two parameters is not null and not 
      #   "whitespace only" string.
      # - It works by summing the count of valid variables (1 if valid, 0 if not) and 
      #   ensuring the total is exactly 1.
      # - Nested if instead of && because terraform do not have short-circuit in logical 
      #   operator evaluation and trimspace want a not-null input.
      condition = (
        (
          (
            var.destination_path != null 
            ? ( trimspace(var.destination_path) != "" ? 1 : 0 )
            : 0
          )
          +
          ( 
            var.file_cache_key != null 
            ? ( trimspace(var.file_cache_key) != "" ? 1 : 0)
            : 0
          )
        )
        == 1
      )

      error_message = <<-EOT
          Validation failed: Exactly one and not both of 'destination_path' or 'file_cache_key'
                    must be specified and must not be a "whitespace only" string.
        EOT
    }

  }

}
