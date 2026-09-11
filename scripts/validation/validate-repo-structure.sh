#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT=""
TARGET_ENV=""
WARNING_ONLY="false"
LEGACY_EXCEPTIONS_FILE=""
ENABLE_ARGOCD_VALIDATION="${ENABLE_ARGOCD_VALIDATION:-false}"
ENABLE_ARGOCD_SCHEMA_VALIDATION="${ENABLE_ARGOCD_SCHEMA_VALIDATION:-false}"
ARGOCD_CRD_SCHEMA_LOCATION="${ARGOCD_CRD_SCHEMA_LOCATION:-}"

info_count=0
warning_count=0
error_count=0
infos=()
warnings=()
issues=()


usage() {
  cat <<'EOF'
Usage: validate-repo-structure.sh [options]

Options:
  --repo-root <path>                 Repository root (required)
  --target-env <env>                 Validate a single environment (required)
  --warning-only                     Report issues as warnings without failing
  --legacy-exceptions-file <path>    File with allowed missing paths, one per line
  --enable-argocd-validation <bool>  Validate ArgoCD structure (true|false) - default: false
  --enable-argocd-schema-validation <bool>  Validate ArgoCD schema with kubeconform (true|false) - default: false
  --argocd-crd-schema-location <path-or-url> Optional kubeconform schema location for ArgoCD CRDs
  --help                             Show this help
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
    --legacy-exceptions-file)
      LEGACY_EXCEPTIONS_FILE="$2"
      shift 2
      ;;
    --enable-argocd-validation)
      ENABLE_ARGOCD_VALIDATION="$2"
      shift 2
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

if [[ "$ENABLE_ARGOCD_VALIDATION" != "true" && "$ENABLE_ARGOCD_VALIDATION" != "false" ]]; then
  echo "Invalid value for --enable-argocd-validation: '$ENABLE_ARGOCD_VALIDATION' (allowed: true|false)"
  usage
  exit 2
fi

if [[ "$ENABLE_ARGOCD_SCHEMA_VALIDATION" != "true" && "$ENABLE_ARGOCD_SCHEMA_VALIDATION" != "false" ]]; then
  echo "Invalid value for --enable-argocd-schema-validation: '$ENABLE_ARGOCD_SCHEMA_VALIDATION' (allowed: true|false)"
  usage
  exit 2
fi

trim() {
  local value="$1"
  value="${value#${value%%[![:space:]]*}}"
  value="${value%${value##*[![:space:]]}}"
  echo "$value"
}

contains_value() {
  local needle="$1"
  shift
  local item
  for item in "$@"; do
    if [[ "$item" == "$needle" ]]; then
      return 0
    fi
  done
  return 1
}

annotation_level() {
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
  issues+=("$file_path: $message")
}

report_info() {
  local file_path="$1"
  local message="$2"
  info_count=$((info_count + 1))
  echo "::notice file=${file_path}::${message}"
  # Also store this info to print it in the summary at the end of the script.
  infos+=("$file_path: $message")
}

declare -a legacy_exceptions
if [[ -n "$LEGACY_EXCEPTIONS_FILE" && -f "$LEGACY_EXCEPTIONS_FILE" ]]; then
  while IFS= read -r line; do
    line="$(trim "$line")"
    if [[ -z "$line" || "$line" == \#* ]]; then
      continue
    fi
    legacy_exceptions+=("$line")
  done < "$LEGACY_EXCEPTIONS_FILE"
fi

is_legacy_exception() {
  local candidate="$1"
  contains_value "$candidate" "${legacy_exceptions[@]:-}"
}

# Ensure yq is available before running YAML-dependent validations.
# Args:
#   $1: context path used in GitHub annotation
#   $2: logical component label for clearer error messages
ensure_yq_available() {
  local context_path="$1"
  local component_name="$2"

  if ! command -v yq >/dev/null 2>&1; then
    report_issue "$context_path" "$component_name requires yq, but the YAML parser is not available (install yq)"
    return 1
  fi

  return 0
}

# Validate YAML syntax for a single file.
validate_yaml() {
  local file_path="$1"

  if ! ensure_yq_available "$file_path" "YAML validation"; then
    return
  fi

  if ! yq eval '.' "$file_path" >/dev/null 2>&1; then
    report_issue "$file_path" "Malformed YAML"
  fi
}


# Delegate ArgoCD validations to the dedicated script.
run_argocd_validation() {
  local validator_script="$1"
  local -a args=(
    --repo-root "$REPO_ROOT"
    --target-env "$TARGET_ENV"
    --enable-argocd-schema-validation "$ENABLE_ARGOCD_SCHEMA_VALIDATION"
    --argocd-crd-schema-location "$ARGOCD_CRD_SCHEMA_LOCATION"
  )

  if [[ "$WARNING_ONLY" == "true" ]]; then
    args+=( --warning-only )
  fi

  if ! bash "$validator_script" "${args[@]}"; then
    report_issue "argocd/${TARGET_ENV}" "ArgoCD validation failed. Check the ArgoCD validation annotations above for details."
  fi
}

cd "$REPO_ROOT"

# Check 1: Validate the presence of required directories (commons / microservices / jobs).
if [[ ! -d commons || ! -d microservices || ! -d jobs ]]; then
  report_issue "." "Invalid repository structure: required directories are commons/, microservices/, jobs/"
fi

# Check 2: commons_env_count is the number of environment directories found in commons/. If none are found, report an issue.
commons_env_count=$(find commons -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
if [ "$commons_env_count" -eq 0 ]; then
  report_issue "commons" "No environments found in commons/"
fi

# These files should be present in commons/<target_env> directory. (TO VERIFY: If this is not the case, we can remove this check.)
required_commons_files=(
  "values-microservice.yaml"
  "values-cronjob.yaml"
  "images.yaml"
  "Chart.yaml"
)

# Check 3: Validate the presence of the commons/<target_env> directory.
env_dir="commons/$TARGET_ENV"
if [[ ! -d "$env_dir" ]]; then
  report_issue "$env_dir" "Missing commons environment directory"
else
  # Check 4: Validate mandatory files for the selected commons target env.
  for required_file in "${required_commons_files[@]}"; do
    required_path="$env_dir/$required_file"
    if [[ ! -f "$required_path" ]]; then
      if ! is_legacy_exception "$required_path"; then
        report_issue "$required_path" "Missing required file"
      fi
      continue
    fi
    # Check 5: Validate that the mandatory files are not empty.
    validate_yaml "$required_path"
  done

  # Check 6: Configmaps directory is mandatory for commons/<target_env> and must not be empty. (TO VERIFY: If this is not the case, we can remove this check.)
  if [[ ! -d "$env_dir/configmaps" ]]; then
    configmaps_path="$env_dir/configmaps"
    if ! is_legacy_exception "$configmaps_path"; then
      report_issue "$configmaps_path" "Missing required directory"
    fi
  fi
fi

validate_workload_group() {
  local group_dir="$1"

  if [[ ! -d "$group_dir" ]]; then
    report_issue "$group_dir" "Missing workload directory"
    return
  fi

  for workload_dir in $(find "$group_dir" -mindepth 1 -maxdepth 1 -type d | sort); do
    env_dir="$workload_dir/$TARGET_ENV"

    # For each workload, missing target env directory is a non-blocking info.
    if [[ ! -d "$env_dir" ]]; then
      report_info "$env_dir" "Missing environment directory for workload $workload_dir"
      continue
    fi

    # values.yaml is mandatory and must not be empty.
    values_path="$env_dir/values.yaml"
    if [[ ! -f "$values_path" ]]; then
      report_issue "$values_path" "Missing required file"
      continue
    fi

    if [[ ! -s "$values_path" ]]; then
      report_issue "$values_path" "Empty values.yaml file"
      continue
    fi

    # Validate that the values.yaml file is a valid YAML file.
    validate_yaml "$values_path"
  done
}

# Check 7: Validate the presence of required workload directories (microservices / jobs) and their target env subdirectories.
validate_workload_group "microservices"
validate_workload_group "jobs"

# Check 8 (optional): Validate ArgoCD base directory and target environment directory.
if [[ "$ENABLE_ARGOCD_VALIDATION" == "true" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  ARGOCD_VALIDATOR_SCRIPT="$SCRIPT_DIR/validate-argocd-manifests.sh"

  if [[ ! -f "$ARGOCD_VALIDATOR_SCRIPT" ]]; then
    report_issue "$ARGOCD_VALIDATOR_SCRIPT" "Missing ArgoCD validator script"
  else
    run_argocd_validation "$ARGOCD_VALIDATOR_SCRIPT"
  fi
fi


summary_msg="Repo structure validation completed. errors=$error_count warnings=$warning_count target_env=$TARGET_ENV"
echo "$summary_msg"

  if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
  {
    echo "### Repo Structure Validation"
    echo
    echo "- target_env: $TARGET_ENV"
    echo "- errors: $error_count"
    echo "- warnings: $warning_count"
    echo "- warning_only: $WARNING_ONLY"
    echo "- enable_argocd_validation: $ENABLE_ARGOCD_VALIDATION"
    echo "- enable_argocd_schema_validation: $ENABLE_ARGOCD_SCHEMA_VALIDATION"
    echo "- argocd_crd_schema_location: ${ARGOCD_CRD_SCHEMA_LOCATION:-<default>}"
    echo ""

    # Print the list of issues if any
    if [[ ${#issues[@]} -gt 0 ]]; then
      echo "#### Issues:"
      for issue in "${issues[@]}"; do
        echo "- $issue"
      done
    fi
    # Print the list of warnings if any
    if [[ ${#warnings[@]} -gt 0 ]]; then
      echo "#### Warnings:"
      for warning in "${warnings[@]}"; do
        echo "- $warning"
      done
    fi
    # Print the list of info if any
    if [[ ${#infos[@]} -gt 0 ]]; then
      echo "#### Info:"
      for info in "${infos[@]}"; do
        echo "- $info"
      done
    fi
  } >> "$GITHUB_STEP_SUMMARY"
fi

if [[ "$WARNING_ONLY" == "false" && $error_count -gt 0 ]]; then
  exit 1
fi

exit 0
