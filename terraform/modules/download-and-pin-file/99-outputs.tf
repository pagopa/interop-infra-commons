output "downloaded_file_location" {
  description = "The same value of \"destination_path\" parameter XOR the path to the file cache"
  value       = local.full_destination_path
}

output "file_sha256_base64" {
  description = ""
  value       = data.external.curl_wrapper.result.file_sha256_base64
}
