#!/usr/bin/env bash

set -euo pipefail

compute_tf_version() {
  local module_dir="$1"
  local module_name
  local tf_files
  local version_declarations
  local declaration_count
  local declaration
  local declaration_file
  local declaration_line
  local declaration_content
  local constraint

  module_name=$(basename "$module_dir")

  # Find all module .tf files, excluding downloaded dependencies under .terraform.
  tf_files=$(cd "$module_dir" && find . -type f -name '*.tf' -not -path './.terraform/*' | sort)

  if [ -z "$tf_files" ]; then
    echo "::error::No Terraform files found for module '$module_name'" >&2
    return 1
  fi

  # grep -H to include filename, -n to include line number, and look for lines that match the required_version pattern
  version_declarations=$(cd "$module_dir" && printf '%s\n' "$tf_files" | while IFS= read -r tf_file; do
    grep -Hn '^[[:space:]]*required_version[[:space:]]*=' "$tf_file" || true
  done)

  # Count the number of required_version declarations found. 
  # sed '/^$/d' removes empty lines, wc -l counts lines, and xargs trims whitespace (declaration_count -> number)
  declaration_count=$(printf '%s\n' "$version_declarations" | sed '/^$/d' | wc -l | xargs)

  if [ "$declaration_count" -eq 0 ]; then
    echo "::error::No required_version constraint found for module '$module_name'" >&2
    return 1
  fi

  if [ "$declaration_count" -gt 1 ]; then
    echo "::error::Multiple required_version constraints found for module '$module_name'" >&2
    printf '%s\n' "$version_declarations" >&2
    return 1
  fi

  # declaration_count is exactly 1, so we can safely extract the single declaration.
  declaration=$(printf '%s\n' "$version_declarations" | sed '/^$/d')
  # declaration format is: filename:line_number:content. 
  # We need to extract the filename and line number to verify the declaration is inside a terraform {} block.
  # %%:* removes the longest suffix starting with ':', leaving the filename.
  declaration_file=${declaration%%:*}
  # #*: removes the shortest prefix ending with ':', leaving line_number:content.
  declaration_line=${declaration#*:}
  # %%:* removes the longest suffix starting with ':', leaving the line number.
  declaration_line=${declaration_line%%:*}

  if ! (
    cd "$module_dir"
    awk -v target_line="$declaration_line" '

      # in_tf tracks whether we are currently inside a terraform {} block. 
      # depth tracks the nesting level of braces to handle nested blocks.
      # ok is set to 1 if we find the required_version declaration at the target line inside a terraform block.
      BEGIN { in_tf = 0; depth = 0; ok = 0 }


      # Detect the start of a terraform block, then set in_tf to 1 and reset depth to 0.
      /^[[:space:]]*terraform[[:space:]]*\{/ {
        in_tf = 1
        depth = 0
      }

      {
        # If we are inside a terraform block, we need to track the depth of nested braces to know when we exit the block.
        # gsub counts the number of '{' and '}' in the line, and we update the depth accordingly.
        if (in_tf) {
          line = $0
          opens = gsub(/\{/, "{", line)
          closes = gsub(/\}/, "}", line)
          depth += opens - closes
        }

        # FNR is the current line number in the file being processed.
        # When we reach the target line, we check if we are inside a terraform block and if the line matches the required_version declaration pattern.
        if (FNR == target_line) {
          if (in_tf && $0 ~ /^[[:space:]]*required_version[[:space:]]*=/) {
            ok = 1
          }
          exit(ok ? 0 : 1)
        }

        # If we are inside a terraform block and the depth is 0 or less, it means we have exited the block,
        # so we reset in_tf to 0.
        if (in_tf && depth <= 0) {
          in_tf = 0
          depth = 0
        }
      }

      END { exit(ok ? 0 : 1) }
    ' "$declaration_file"
  ); then
    # awk exit was 1
    echo "::error::required_version in module '$module_name' must be declared inside the terraform {} block" >&2
    printf '%s\n' "$version_declarations" >&2
    return 1
  fi
  
  declaration_content=${declaration#*:*:}
  constraint=${declaration_content#*=}
  constraint=${constraint//\"/}
  constraint=$(echo "$constraint" | xargs)

  echo "$constraint"
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <module-dir>" >&2
    exit 1
  fi

  compute_tf_version "$1"
fi
