#!/usr/bin/env bash

set -euo pipefail

# -----------------------------------------------------------------------------
# Runtime configuration (overridable via CLI options)
# -----------------------------------------------------------------------------
REPO_ROOT=""
TARGET_ENV=""
WARNING_ONLY="false"
ENABLE_ARGOCD_SCHEMA_VALIDATION="true"
ARGOCD_CRD_SCHEMA_LOCATION=""
DEFAULT_ARGOCD_CRD_SCHEMA_LOCATION="https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json"

# Aggregated execution counters printed in the final summary.
warning_count=0
error_count=0
info_count=0

# Cache for normalized local repository URLs resolved once per script run.
# Purpose: avoid repeated git/CI URL resolution for each validated path.
LOCAL_REPO_URLS_CACHE=""

# Absolute path to this script directory, used to source helper modules.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load helper modules.
# shellcheck source=/dev/null
source "$SCRIPT_DIR/validate-argocd-tooling-repo-helpers.sh"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/validate-argocd-template-path-helpers.sh"

# -----------------------------------------------------------------------------
# CLI parsing and argument validation
# -----------------------------------------------------------------------------
usage() {
  cat <<'EOF'
Usage: validate-argocd-manifests.sh [options]

Options:
  --repo-root <path>                    Repository root (required)
  --target-env <env>                    Environment to validate under argocd/<env> (required)
  --warning-only                        Report issues as warnings without failing
  --enable-argocd-schema-validation <bool>  Validate ArgoCD schema with kubeconform (true|false)
  --argocd-crd-schema-location <path-or-url> Optional kubeconform schema location for ArgoCD CRDs
                                           Default: https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json
  --help                                Show this help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo-root)
      REPO_ROOT="$2"
      shift 2
      ;;
    --target-env)
      TARGET_ENV="$2"
      shift 2
      ;;
    --warning-only)
      WARNING_ONLY="true"
      shift
      ;;
    --enable-argocd-schema-validation)
      ENABLE_ARGOCD_SCHEMA_VALIDATION="$2"
      shift 2
      ;;
    --argocd-crd-schema-location)
      ARGOCD_CRD_SCHEMA_LOCATION="$2"
      shift 2
      ;;
    --help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1"
      usage
      exit 2
      ;;
  esac
done

if [[ -z "$REPO_ROOT" ]]; then
  echo "Missing required argument: --repo-root"
  usage
  exit 2
fi

if [[ -z "$TARGET_ENV" ]]; then
  echo "Missing required argument: --target-env"
  usage
  exit 2
fi

if [[ ! -d "$REPO_ROOT" ]]; then
  echo "Invalid --repo-root path: '$REPO_ROOT'"
  exit 2
fi

# Normalize repository root once to keep all path checks deterministic.
REPO_ROOT="$(cd "$REPO_ROOT" && pwd)"

if [[ "$ENABLE_ARGOCD_SCHEMA_VALIDATION" != "true" && "$ENABLE_ARGOCD_SCHEMA_VALIDATION" != "false" ]]; then
  echo "Invalid value for --enable-argocd-schema-validation: '$ENABLE_ARGOCD_SCHEMA_VALIDATION' (allowed: true|false)"
  usage
  exit 2
fi

# -----------------------------------------------------------------------------
# Reporting helpers
# -----------------------------------------------------------------------------
annotation_level() {
  # In warning-only mode, every issue is downgraded to warning.
  if [[ "$WARNING_ONLY" == "true" ]]; then
    echo "warning"
  else
    echo "error"
  fi
}

report_issue() {
  local file_path="$1"
  local message="$2"
  local level
  level="$(annotation_level)"

  if [[ "$level" == "error" ]]; then
    error_count=$((error_count + 1))
  else
    warning_count=$((warning_count + 1))
  fi

  echo "::${level} file=${file_path}::${message}"
}

report_info() {
  local file_path="$1"
  local message="$2"
  info_count=$((info_count + 1))
  echo "::notice file=${file_path}::${message}"
}

# -----------------------------------------------------------------------------
# Core validation primitives
# -----------------------------------------------------------------------------
validate_existing_reference() {
  # Validate an already-normalized and (if needed) already-expanded path.
  local manifest_path="$1"
  local field_name="$2"
  local raw_path="$3"
  local expected_type="$4" # file|dir|any
  local normalized="$5"

  local candidate_path="$REPO_ROOT"
  if [[ -n "$normalized" ]]; then
    candidate_path="$REPO_ROOT/$normalized"
  fi

  if path_has_glob_or_template "$normalized"; then
    if ! path_exists_by_glob "$candidate_path"; then
      report_issue "$manifest_path" "$field_name references missing path pattern: $raw_path"
    fi
    return
  fi

  case "$expected_type" in
    file)
      if [[ ! -f "$candidate_path" ]]; then
        report_issue "$manifest_path" "$field_name references missing file: $raw_path"
      fi
      ;;
    dir)
      if [[ ! -d "$candidate_path" ]]; then
        report_issue "$manifest_path" "$field_name references missing directory: $raw_path"
      fi
      ;;
    any)
      if [[ ! -e "$candidate_path" ]]; then
        report_issue "$manifest_path" "$field_name references missing path: $raw_path"
      fi
      ;;
    *)
      report_issue "$manifest_path" "Internal validator error: unsupported expected_type '$expected_type'"
      ;;
  esac
}

path_exists_by_glob() {
  # Resolve wildcard patterns relative to repository root.
  local pattern="$1"

  if [[ "$pattern" == *"*"* || "$pattern" == *"?"* || "$pattern" == *"["* ]]; then
    find "$REPO_ROOT" -path "$pattern" -print -quit | grep -q .
  else
    [[ -e "$pattern" ]]
  fi
}

normalize_repo_relative_path() {
  # Normalize ArgoCD value-file notation and local relative prefixes.
  local raw_path="$1"
  local normalized="$raw_path"

  normalized="${normalized#\$values/}"
  normalized="${normalized#./}"

  echo "$normalized"
}

validate_repo_reference() {
  # Main path validator used by source/generator checks.
  # It is repo-aware and template-aware.
  local manifest_path="$1"
  local field_name="$2"
  local raw_path="$3"
  local expected_type="$4" # file|dir|any
  local source_repo_url="${5:-}"

  if ! repo_points_to_local_workspace "$source_repo_url"; then
    # Local existence checks are not meaningful for external repositories.
    report_info "$manifest_path" "$field_name points to external repo '$source_repo_url'; local path existence validation skipped for path: $raw_path"
    return
  fi

  if [[ -z "$raw_path" || "$raw_path" == "null" ]]; then
    report_issue "$manifest_path" "$field_name is empty"
    return
  fi

  local normalized
  normalized="$(normalize_repo_relative_path "$raw_path")"

  if [[ "$normalized" == "." ]]; then
    normalized=""
  fi

  if path_contains_template_placeholder "$normalized"; then
    # Expand placeholders when possible and validate only concrete candidates.
    local resolved_any="false"
    local unresolved_any="false"
    local resolved_path

    while IFS= read -r resolved_path; do
      if path_contains_template_placeholder "$resolved_path"; then
        unresolved_any="true"
        continue
      fi

      resolved_any="true"
      validate_existing_reference "$manifest_path" "$field_name" "$raw_path" "$expected_type" "$resolved_path"
    done < <(expand_template_paths_with_list_values "$manifest_path" "$normalized")

    if [[ "$resolved_any" == "false" ]]; then
      report_info "$manifest_path" "$field_name contains unresolved template placeholders and could not be expanded for local path validation: $raw_path"
    elif [[ "$unresolved_any" == "true" ]]; then
      report_info "$manifest_path" "$field_name contains partially unresolved template placeholders; only fully expanded candidates were validated: $raw_path"
    fi
    return
  fi

  validate_existing_reference "$manifest_path" "$field_name" "$raw_path" "$expected_type" "$normalized"
}

validate_source_include_pattern() {
  # Validate include glob relative to the corresponding source path.
  local manifest_path="$1"
  local field_name="$2"
  local base_path="$3"
  local include_pattern="$4"
  local source_repo_url="${5:-}"

  if ! repo_points_to_local_workspace "$source_repo_url"; then
    report_info "$manifest_path" "$field_name points to external repo '$source_repo_url'; local include pattern validation skipped"
    return
  fi

  if [[ -z "$include_pattern" || "$include_pattern" == "null" ]]; then
    return
  fi

  local normalized_base
  normalized_base="$(normalize_repo_relative_path "$base_path")"
  local base_dir="$REPO_ROOT"
  if [[ -n "$normalized_base" ]]; then
    base_dir="$REPO_ROOT/$normalized_base"
  fi

  if [[ ! -d "$base_dir" ]]; then
    report_issue "$manifest_path" "$field_name cannot be validated because base path is missing: $base_path"
    return
  fi

  local include_glob="$base_dir/$include_pattern"
  if ! path_exists_by_glob "$include_glob"; then
    report_issue "$manifest_path" "$field_name references missing include pattern '$include_pattern' under '$base_path'"
  fi
}

validate_yaml() {
  # Fast syntax validation for each YAML manifest.
  local file_path="$1"

  if ! ensure_yq_available "$file_path" "YAML validation"; then
    return
  fi

  if ! yq eval '.' "$file_path" >/dev/null 2>&1; then
    report_issue "$file_path" "Malformed YAML"
  fi
}

validate_schema_with_kubeconform() {
  # Optional schema validation layer.
  local manifest_file="$1"

  if [[ "$ENABLE_ARGOCD_SCHEMA_VALIDATION" != "true" ]]; then
    return
  fi
  if ! command -v kubeconform >/dev/null 2>&1; then
    report_info "$manifest_file" "kubeconform not available; skipping schema validation"
    return
  fi

  local output
  local schema_location
  local -a kubeconform_cmd=(kubeconform -strict)

  schema_location="$DEFAULT_ARGOCD_CRD_SCHEMA_LOCATION"
  if [[ -n "$ARGOCD_CRD_SCHEMA_LOCATION" ]]; then
    # Explicit input overrides default CRD schema location.
    schema_location="$ARGOCD_CRD_SCHEMA_LOCATION"
  fi

  kubeconform_cmd+=( -schema-location default -schema-location "$schema_location" )

  # kubeconform output is sent to stderr, so we capture it and check the exit code.
  # kubeconform output is 0 for valid manifests, 1 for invalid manifests, and 2 for errors (e.g., missing schema).
  if ! output="$("${kubeconform_cmd[@]}" "$manifest_file" 2>&1)"; then
    report_issue "$manifest_file" "Schema validation failed (kubeconform): ${output//$'\n'/ ; }"
  fi
}

# -----------------------------------------------------------------------------
# Kind-specific validators
# -----------------------------------------------------------------------------
validate_argocd_application_manifest() {
  # Application supports either spec.source.path or spec.sources[].path.
  # At least one of them must be present.
  local manifest_file="$1"

  local source_path_value
  source_path_value="$(yq eval -r '.spec.source.path // ""' "$manifest_file")"

  local sources_path_count
  sources_path_count="$(yq eval -r '.spec.sources[]?.path' "$manifest_file" | awk 'NF { c++ } END { print c+0 }')"

  local source_repo_url
  source_repo_url="$(yq eval -r '.spec.source.repoURL // ""' "$manifest_file")"

  if [[ -n "$source_path_value" ]]; then
    validate_repo_reference "$manifest_file" "spec.source.path" "$source_path_value" "dir" "$source_repo_url"
  fi

  if [[ "$sources_path_count" -eq 0 && -z "$source_path_value" ]]; then
    report_issue "$manifest_file" "Either spec.source.path or spec.sources[].path must be set"
  fi

  while IFS=$'\t' read -r source_path repo_url; do
    [[ -n "$source_path" ]] || continue
    validate_repo_reference "$manifest_file" "spec.sources[].path" "$source_path" "dir" "$repo_url"
  done < <(yq eval -r '.spec.sources[]? | [.path // "", .repoURL // ""] | @tsv' "$manifest_file")

  while IFS=$'\t' read -r source_path include_pattern; do
    validate_source_include_pattern "$manifest_file" "spec.source.directory.include" "$source_path" "$include_pattern" "$source_repo_url"
  done < <(yq eval -r '[.spec.source.path // "", .spec.source.directory.include // ""] | @tsv' "$manifest_file")

  while IFS=$'\t' read -r source_path include_pattern repo_url; do
    validate_source_include_pattern "$manifest_file" "spec.sources[].directory.include" "$source_path" "$include_pattern" "$repo_url"
  done < <(yq eval -r '.spec.sources[]? | [.path // "", .directory.include // "", .repoURL // ""] | @tsv' "$manifest_file")
}

validate_argocd_applicationset_manifest() {
  # ApplicationSet validates generator paths and template source references.
  local manifest_file="$1"

  local template_source_path_value
  template_source_path_value="$(yq eval -r '.spec.template.spec.source.path // ""' "$manifest_file")"

  local template_sources_path_count
  template_sources_path_count="$(yq eval -r '.spec.template.spec.sources[]?.path' "$manifest_file" | awk 'NF { c++ } END { print c+0 }')"

  local template_source_repo_url
  template_source_repo_url="$(yq eval -r '.spec.template.spec.source.repoURL // ""' "$manifest_file")"

  if [[ -n "$template_source_path_value" ]]; then
    validate_repo_reference "$manifest_file" "spec.template.spec.source.path" "$template_source_path_value" "dir" "$template_source_repo_url"
  fi

  if [[ "$template_sources_path_count" -eq 0 && -z "$template_source_path_value" ]]; then
    report_issue "$manifest_file" "Either spec.template.spec.source.path or spec.template.spec.sources[].path must be set"
  fi

  while IFS=$'\t' read -r source_path repo_url; do
    [[ -n "$source_path" ]] || continue
    validate_repo_reference "$manifest_file" "spec.template.spec.sources[].path" "$source_path" "dir" "$repo_url"
  done < <(yq eval -r '.spec.template.spec.sources[]? | [.path // "", .repoURL // ""] | @tsv' "$manifest_file")

  while IFS= read -r value_file; do
    validate_repo_reference "$manifest_file" "spec.template.spec.source.helm.valueFiles[]" "$value_file" "file"
  done < <(yq eval -r '.spec.template.spec.source.helm.valueFiles[]?' "$manifest_file")

  while IFS= read -r value_file; do
    validate_repo_reference "$manifest_file" "spec.template.spec.sources[].helm.valueFiles[]" "$value_file" "file"
  done < <(yq eval -r '.spec.template.spec.sources[]?.helm.valueFiles[]?' "$manifest_file")

  while IFS=$'\t' read -r source_path include_pattern; do
    validate_source_include_pattern "$manifest_file" "spec.template.spec.source.directory.include" "$source_path" "$include_pattern" "$template_source_repo_url"
  done < <(yq eval -r '[.spec.template.spec.source.path // "", .spec.template.spec.source.directory.include // ""] | @tsv' "$manifest_file")

  while IFS=$'\t' read -r source_path include_pattern repo_url; do
    validate_source_include_pattern "$manifest_file" "spec.template.spec.sources[].directory.include" "$source_path" "$include_pattern" "$repo_url"
  done < <(yq eval -r '.spec.template.spec.sources[]? | [.path // "", .directory.include // "", .repoURL // ""] | @tsv' "$manifest_file")
}

validate_argocd_manifests() {
  # Scan argocd/TARGET_ENV and dispatch validation by manifest kind.
  local argocd_root_dir="$1"

  if ! ensure_yq_available "$argocd_root_dir" "ArgoCD manifest validation"; then
    return
  fi

  local manifest_files=()
  while IFS= read -r f; do
    manifest_files+=("$f")
  done < <(find "$argocd_root_dir" -type f \( -name '*.yaml' -o -name '*.yml' \) | sort)

  if [[ ${#manifest_files[@]} -eq 0 ]]; then
    report_issue "$argocd_root_dir" "No ArgoCD YAML manifests found"
    return
  fi

  local manifest_file
  for manifest_file in "${manifest_files[@]}"; do
    echo "  - Validating ArgoCD manifest: $manifest_file"
    validate_yaml "$manifest_file"
    validate_schema_with_kubeconform "$manifest_file"

    local kind
    kind="$(yq eval -r '.kind // ""' "$manifest_file" 2>/dev/null || true)"
    
    case "$kind" in
      Application)
        validate_argocd_application_manifest "$manifest_file"
        ;;
      ApplicationSet)
        validate_argocd_applicationset_manifest "$manifest_file"
        ;;
      "")
        report_issue "$manifest_file" "Missing Kubernetes kind"
        ;;
    esac
  done
}

echo "=================================================="
echo "Starting ArgoCD validation for environment: $TARGET_ENV"
echo "=================================================="
cd "$REPO_ROOT"

argocd_root_dir="argocd"
argocd_env_dir="${argocd_root_dir}/${TARGET_ENV}"

if [[ ! -d "$argocd_root_dir" ]]; then
  report_issue "$argocd_root_dir" "Missing required ArgoCD root directory"
elif [[ ! -d "$argocd_env_dir" ]]; then
  report_issue "$argocd_env_dir" "Missing required ArgoCD environment directory"
else
  validate_argocd_manifests "$argocd_env_dir"
fi

echo "ArgoCD validation completed. errors=$error_count warnings=$warning_count infos=$info_count target_env=$TARGET_ENV"

if [[ "$WARNING_ONLY" == "false" && $error_count -gt 0 ]]; then
  exit 1
fi

exit 0
