#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# Tooling and repository URL resolution helpers
# -----------------------------------------------------------------------------
# Expected from main script:
# - Variables: REPO_ROOT, LOCAL_REPO_URLS_CACHE
# - Optional env: GITHUB_SERVER_URL, GITHUB_REPOSITORY
# - Function: report_issue
ensure_yq_available() {
  local context_path="$1"
  local component_name="$2"

  if ! command -v yq >/dev/null 2>&1; then
    report_issue "$context_path" "$component_name requires yq, but the YAML parser is not available (install yq)"
    return 1
  fi

  return 0
}

normalize_repo_url() {
  # Canonicalize GitHub repository URLs to owner/repo (no .git suffix).
  # Supported examples:
  # - git@github.com:owner/repo.git
  # - ssh://git@github.com/owner/repo.git
  # - https://github.com/owner/repo.git
  # - git://github.com/owner/repo.git
  local repo_url="$1"
  local normalized="$repo_url"

  # Remove leading/trailing whitespace and .git suffix for comparison.
  normalized="${normalized## }"
  normalized="${normalized%% }"
  normalized="${normalized%.git}"

  # Extract owner/repo when URL points to github.com.
  # For protocol URLs we strip protocol and optional userinfo first.
  if [[ "$normalized" == ssh://* || "$normalized" == http://* || "$normalized" == https://* || "$normalized" == git://* ]]; then
    normalized="${normalized#*://}"
    normalized="${normalized#*@}"
    if [[ "$normalized" == github.com/* ]]; then
      normalized="${normalized#github.com/}"
    fi
  elif [[ "$normalized" == *"@github.com:"* ]]; then
    normalized="${normalized#*@github.com:}"
  elif [[ "$normalized" == github.com/* ]]; then
    normalized="${normalized#github.com/}"
  fi

  # Remove trailing slash to avoid false mismatches.
  normalized="${normalized%/}"
  echo "$normalized"
}

populate_local_repo_urls_cache() {
  # Populate cache only once in the current shell process.
  if [[ -n "$LOCAL_REPO_URLS_CACHE" ]]; then
    return
  fi

  local -a urls=()
  local remote_url

  # Primary source: git remotes from local checkout.
  if command -v git >/dev/null 2>&1; then
    while IFS= read -r remote_url; do
      [[ -n "$remote_url" ]] || continue
      urls+=("$(normalize_repo_url "$remote_url")")
    done < <(git -C "$REPO_ROOT" remote get-url --all origin 2>/dev/null || true)

    while IFS= read -r remote_url; do
      [[ -n "$remote_url" ]] || continue
      urls+=("$(normalize_repo_url "$remote_url")")
    done < <(git -C "$REPO_ROOT" remote get-url --all upstream 2>/dev/null || true)
  fi

  # GitHub Actions fallback when remotes are unavailable in CI checkout.
  if [[ -n "${GITHUB_REPOSITORY:-}" ]]; then
    local server_url
    server_url="${GITHUB_SERVER_URL:-https://github.com}"
    server_url="${server_url%/}"
    urls+=("$(normalize_repo_url "${server_url}/${GITHUB_REPOSITORY}")")
    urls+=("$(normalize_repo_url "git@github.com:${GITHUB_REPOSITORY}")")
  fi

  # Fallback marker for local/self references.
  urls+=(".")

  # Save unique normalized URLs as a newline-separated list.
  LOCAL_REPO_URLS_CACHE="$(printf '%s\n' "${urls[@]}" | awk 'NF' | sort -u)"
}

repo_points_to_local_workspace() {
  # Decide whether path existence must be checked against this local workspace
  # or skipped because the source points to an external repository.
  local repo_url="$1"

  # Empty repoURL means the caller cannot determine source repository.
  # Keep validating locally to preserve current behavior.
  if [[ -z "$repo_url" || "$repo_url" == "null" ]]; then
    return 0
  fi

  local normalized_repo_url
  normalized_repo_url="$(normalize_repo_url "$repo_url")"

  local repo_name
  repo_name="$(basename "$REPO_ROOT")"

  # Ensure cache is computed in current shell (not in subshell).
  populate_local_repo_urls_cache

  local local_repo_url
  while IFS= read -r local_repo_url; do
    if [[ "$normalized_repo_url" == "$local_repo_url" ]]; then
      return 0
    fi
  done <<< "$LOCAL_REPO_URLS_CACHE"

  # Fallback: when remotes are unavailable in CI/local clones, consider URLs
  # ending with the current repository directory name as local.
  if [[ "$normalized_repo_url" == */"$repo_name" ]]; then
    return 0
  fi

  return 1
}
