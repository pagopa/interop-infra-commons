#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# Template and path manipulation helpers
# -----------------------------------------------------------------------------
# Expected from main script:
# - External tools: yq, grep, sed, awk
# - Manifest path inputs passed by caller functions
path_has_glob_or_template() {
  local path="$1"
  [[ "$path" == *"{{"* || "$path" == *"*"* || "$path" == *"?"* || "$path" == *"["* ]]
}

path_contains_template_placeholder() {
  local path="$1"
  [[ "$path" == *"{{"* ]]
}

collect_template_placeholder_keys() {
  # Extract placeholders in form {{ .key }} from a template string.
  local path="$1"

  echo "$path" \
    | grep -oE '{{[[:space:]]*\.[A-Za-z0-9_.-]+[[:space:]]*}}' \
    | sed -E 's/^{{[[:space:]]*\.([A-Za-z0-9_.-]+)[[:space:]]*}}$/\1/' \
    | sort -u
}

collect_appset_list_values_for_key() {
  # Collect key values from list generators at root, matrix, and merge levels.
  local manifest_path="$1"
  local key_name="$2"

  {
    yq eval -r ".spec.generators[]?.list?.elements[]?[\"${key_name}\"]" "$manifest_path"
    yq eval -r ".spec.generators[]?.matrix?.generators[]?.list?.elements[]?[\"${key_name}\"]" "$manifest_path"
    yq eval -r ".spec.generators[]?.merge?.generators[]?.list?.elements[]?[\"${key_name}\"]" "$manifest_path"
  } | awk 'NF' | sort -u
}

expand_template_paths_with_list_values() {
  # Expand a templated path into all concrete candidates resolvable from
  # ApplicationSet list generator values.
  local manifest_path="$1"
  local path_template="$2"

  local -a placeholder_keys=()
  local key
  while IFS= read -r key; do
    [[ -n "$key" ]] && placeholder_keys+=("$key")
  done < <(collect_template_placeholder_keys "$path_template")

  if [[ ${#placeholder_keys[@]} -eq 0 ]]; then
    echo "$path_template"
    return
  fi

  local -a candidates=("$path_template")
  for key in "${placeholder_keys[@]}"; do
    local -a key_values=()
    local value
    while IFS= read -r value; do
      [[ -n "$value" ]] && key_values+=("$value")
    done < <(collect_appset_list_values_for_key "$manifest_path" "$key")

    if [[ ${#key_values[@]} -eq 0 ]]; then
      continue
    fi

    local -a expanded_candidates=()
    local candidate
    for candidate in "${candidates[@]}"; do
      local matched="false"
      for value in "${key_values[@]}"; do
        local replacement="$value"
        replacement="${replacement//\\/\\\\}"
        replacement="${replacement//&/\\&}"
        replacement="${replacement//\//\\/}"
        local resolved
        resolved="$(echo "$candidate" | sed -E "s/{{[[:space:]]*\\.${key}[[:space:]]*}}/${replacement}/g")"
        if [[ "$resolved" != "$candidate" ]]; then
          expanded_candidates+=("$resolved")
          matched="true"
        fi
      done

      # Keep unresolved candidate so later placeholder rounds may resolve it.
      if [[ "$matched" == "false" ]]; then
        expanded_candidates+=("$candidate")
      fi
    done

    candidates=("${expanded_candidates[@]}")
  done

  printf '%s\n' "${candidates[@]}" | awk 'NF' | sort -u
}
