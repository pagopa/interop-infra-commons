output "well_known_body" {
  description = "The plain text body of the well_known file"
  value       = data.external.well_known_body_generation.result.output
}
